#######################################################################
# The Accounts controller manages the users interaction associated
# with setting up a payment account. The payment account information
# is associated with the Stripe.com service.
#######################################################################
class AccountsController < ApplicationController

  respond_to :html

  # Before filters -----------------------------------------------------
  before_filter :authenticate_user!

  before_action :set_user

  # CANCAN AUTHORIZATION -----------------------------------------------
  # This helper assumes that the instance variable @group is loaded
  # or checks Class permissions
  authorize_resource


  ######################################################################
  # GET    /admin/users/:user_id/accounts/new(.:format)
  #
  # The new action will present a AJAX based form to user as part of
  # the User views. If there is an error it will redirect to the
  # admin_oops_url with a corresponding error message.
  ######################################################################
  def new
    begin
      @user.account = Account.new
      @user.reload
      @account = @user.account
  	rescue Stripe::StripeError => stripe_error
      flash[:alert] = "Stripe error associated with account error = #{stripe_error.message}"
      redirect_to user_url(@user)
    end
  end

  ######################################################################
  # POST   /admin/users/:user_id/accounts(.:format)
  #
  # The create method will update the account settings with the
  # stripe.com customer_id and set the status of the account to ACTIVE
  ######################################################################
  def create
    @user.account = Account.new if @user.account.nil?

    if @user.account.save_with_stripe(params)
      redirect_to user_url(@user), notice: 'Account was successfully created.'
    else
      handle_account_errors(@user, params)
      render action: :new
    end
  end

  ######################################################################
  # GET    /admin/users/:user_id/accounts/:id/edit
  #
  # The edit action will present the user with a form for editing the
  # account record for credit card updates.
  ######################################################################
  def edit
    if @account.present?
      unless @account.get_customer
        flash[:alert] = "Stripe error - could not get customer data."
        redirect_to user_url(@user)
      end
    else
      flash[:alert] = "We could not find the requested credit card account."
      redirect_to admin_oops_url
    end
  end

  ######################################################################
  # PUT or PATCH  /admin/users/:user_id/accounts/:id(.:format)
  #
  # Updates an embedded account record for a user profile. The edit
  # view will direct the user to Stripe.com for entering their credit
  # card information. From there, they are redirected back to this action
  # for updatig the account record.
  ######################################################################
  def update
    if @account.present?

      if @user.account.update_with_stripe(params)
        redirect_to user_url(@user), notice: 'Account was successfully updated.'
      else
        handle_account_errors(@user, params)
        render action: :edit
      end

    else
      flash[:alert] = "We could not find the requested credit card account."
      redirect_to user_url(@user)
    end
  end

  ######################################################################
  # DELETE /admin/users/:user_id/accounts/:id(.:format)
  #
  # The destroy method will destroy the account record associated with
  # the user and destory the customer record on the stripe.com service.
  ######################################################################
  def destroy
    # Added the following check, because we could not CANCAN ability to
    # operate correctly.
    if (@user.id != current_user.id) && (current_user.role == User::CUSTOMER)

      flash[:alert] = "You are not authorized to access the requested User."
      redirect_to admin_oops_url

    else

      if @account.present?
        begin
          @user.account.destroy
          redirect_to users_url, notice: "User credit card deleted."
        rescue Stripe::StripeError => stripe_error
          flash[:alert] = "Error deleting credit card account - #{stripe_error.message}"
          redirect_to user_url(@user)
        end
      else
        flash[:alert] = "Could not find user credit card account to delete."
        redirect_to user_url(@user)
      end

    end

  end


  # PROTECTED INSTANCE METHODS =----------------------------------------
  protected

  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and redirect with error message
  ####################################################################
  def set_user
    @user = User.find(params[:user_id])
    authorize! :update, @user

    if @user.account.present? && @user.account.id.to_s == params[:id]
      @account = @user.account
    else
      @account = nil
    end
  end

  #####################################################################
  # A helper method for setting the account instance variable.
  #####################################################################
  def handle_account_errors(user, params)
    @verrors = user.account.errors.full_messages
    @account = user.account
    @account.stripe_cc_token = @user.account.errors[:customer_id].present? ? nil :
      params[:account][:stripe_cc_token]
    @account.cardholder_name = params[:cardholder_name]
    @account.cardholder_email = params[:cardholder_email]
  end
end
