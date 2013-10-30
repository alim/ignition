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
  
  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.all
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.json
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
      redirect_to subscription_url(@subplan)
    end
  end

  # GET /subscriptions/1/edit
  def edit
  end

  # POST /subscriptions
  # POST /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)
    current_user.subscriptions << @subscription
    
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
    respond_to do |format|
      if @subscription.update(subscription_params)
        format.html { redirect_to @subscription, notice: 'Subscription was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription.destroy
    respond_to do |format|
      format.html { redirect_to subscriptions_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def subscription_params
      params.require(:subscription).permit(:plan_id, :stripe_id, :cancel_at_period_end, :stripe_customer_id, :quantity, :sub_start, :sub_end, :status, :canceled_at, :current_period_start, :current_period_end, :ended_at, :trial_start, :trial_end)
    end
    
    ####################################################################
    # Little helper method to set an instance varialble that is used
    # to flag menu items with an active CSS class for highlighting.
    ####################################################################
    def set_active
      @subscriptions_active="class=active"
    end
end
