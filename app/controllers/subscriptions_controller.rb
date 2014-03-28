########################################################################
# The SubscriptionsController is responsible for subscribing a customer
# to our web service. It depends on the account resource which should
# hold a customer_id associated witht the Stripe.com service. It will
# also depend on the existance of one or more subscription plans being
# setup on the Stripe.com service for charging.
########################################################################
class SubscriptionsController < ApplicationController
  # Before filters & actions -------------------------------------------
  before_filter :authenticate_user!
  
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  before_action :set_active # Sets the variable for active CSS class
  
  ######################################################################
  # GET /subscriptions
  # GET /subscriptions.json
  #
  # The index method will only be available for service administrators
  ######################################################################
  def index
    @subscriptions = Subscription.all
  end

  ######################################################################
  # GET /subscriptions/1
  # GET /subscriptions/1.json
  #
  # The show method will display the list of subscription attributes
  # that were returned from Stripe.com and stored in the Subscription
  # model class.
  ######################################################################
  def show
  end

  ######################################################################
  # GET /subscriptions/new
  #
  # This method will present the customer with a new subscription for,
  # if the customer does not already have a subscription associated
  # with their account. If they do have a subscription, they will be
  # directed to the Subscriptions#show action.
  ######################################################################
  def new
    @subscription = Subscription.new
    
    # Check to see if the logged in user has a subscription already
    @subplan = Subscription.where(user_id: current_user.id).first
    
    if @subplan.present?
      # Subscription plan is active
      redirect_to subscription_url(@subplan)
      
    elsif current_user.account.present?
      # We have an account for signing up a subscription
      
      @subscription.subscribe(current_user.account, params[:plan_id], coupon: params[:coupon_code])
    else
      # No account and no subscription plan - Redirect to update
      # user account with notice to add credit card.
      redirect_to new_user_account_url(current_user.id)
    end
  end

  ######################################################################
  # GET /subscriptions/1/edit
  #
  # Standard edit action and view. Instructions added to the view
  # about updating their subscription plan. We added a partial to 
  # display the plan options.
  ######################################################################
  def edit
  end

  ######################################################################
  # POST /subscriptions
  # POST /subscriptions.json
  #
  # The create method will fill out the subscription options and calls
  # the model instance method for creating a subscription on the 
  # Stripe.com
  ######################################################################
  def create
    @subscription = Subscription.new(subscription_params)
    current_user.subscriptions << @subscription
    #binding.pry
    @subscription.subscribe(current_user.account, subscription_params[:stripe_plan_id], subscription_params[:coupon_code])
    
    # Create a subscription with the following information:
    #
    #   1) Customer Account
    #   2) Subscription Type (GOLD, Silver, etc.) 
    #   3) Discount Coupom (if applicable)

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to @subscription, notice: 'Subscription was successfully created.' }
        format.json { render action: 'show', status: :created, location: @subscription }
      else
        @verrors = @subscription.errors.full_messages
        format.html { render action: 'new' }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriptions/1
  # PATCH/PUT /subscriptions/1.json
  def update
    #binding.pry
    @subscription.subscribe(current_user.account, subscription_params[:stripe_plan_id], coupon: subscription_params[:coupon_code])

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to @subscription, notice: 'Subscription was successfully updated.' }
        format.json { head :no_content }
      else
        @verrors =  @subscription.errors.full_messages
        format.html { render action: 'edit' }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  ##########################################################################
  # DELETE 
  #
  # This method will cancel a Stripe subscription and then destroy the
  # subscription record associated with the user and customer account.
  ##########################################################################
  def destroy
    # First cancel the Stripe subscription

    @subscription.cancel_subscription(current_user.account)
    # Then destroy the subscription record
    @subscription.delete

    respond_to do |format|
      format.html { redirect_to subscriptions_url }
      format.json { head :no_content }
    end
  end
  
  ## PRIVATE INSTANCE METHODS ------------------------------------------

  private
    ## STUB METHOD UNTIL SUBSCRIPTION MODEL HAS BEEN UPDATED
    def update_subscription(subscription)
      subscription.quantity = 1
      subscription.sub_start = DateTime.now
    end
  
  
    ####################################################################
    # Use callbacks to share common setup or constraints between actions.
    ####################################################################
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    ####################################################################
    # Never trust parameters from the scary internet, only allow the 
    # white list through.
    ####################################################################
    def subscription_params
      params.require(:subscription).permit(:stripe_plan_id, 
        :cancel_at_period_end, :quantity, :sub_start, :sub_end, :status, 
        :canceled_at, :current_period_start, :current_period_end, 
        :ended_at, :trial_start, :trial_end, :coupon_code)
    end
    
    ####################################################################
    # Little helper method to set an instance varialble that is used
    # to flag menu items with an active CSS class for highlighting.
    ####################################################################
    def set_active
      @subscriptions_active="class=active"
    end
end
