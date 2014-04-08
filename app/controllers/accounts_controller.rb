class AccountsController < ApplicationController

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
    respond_to do |format|
      begin
        @user.account = Account.new
        @user.reload
        @account = @user.account
      	format.html
    	rescue Stripe::StripeError => stripe_error
        flash[:alert] = "Stripe error associated with account error = #{stripe_error.message}"
        format.html {redirect_to user_url(@user)}
      end
    end
  end

  ######################################################################
  # POST   /admin/users/:user_id/accounts(.:format)
  #
  # The create method will update the account settings with the
  # stripe.com customer_id and set the status of the account to ACTIVE
  ######################################################################
  def create
    respond_to do |format|
      @user.account = Account.new if @user.account.nil?

      if @user.account.save_with_stripe(params)
        # We saved the account, now redirect to the show page
        format.html { redirect_to user_url(@user), notice: 'Account was successfully created.' }
      else
        @verrors = @user.account.errors.full_messages
        @account = @user.account
        @account.stripe_cc_token = @user.account.errors[:customer_id].present? ? nil :
          params[:account][:stripe_cc_token]

        @account.cardholder_name = params[:cardholder_name]
        @account.cardholder_email = params[:cardholder_email]

        format.html { render action: :new }
      end
    end
  end

  ######################################################################
  # GET    /admin/users/:user_id/accounts/:id/edit
  #
  # The edit action will present the user with a form for editing the
  # account record for credit card updates.
  ######################################################################
  def edit
    respond_to do |format|
      if @account.present?
        if @account.get_customer
          format.html
        else
          flash[:alert] = "Stripe error - could not get customer data."
          format.html {redirect_to user_url(@user)}
        end
      else
        flash[:alert] = "We could not find the requested credit card account."
        format.html {redirect_to admin_oops_url}
      end
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
    respond_to do |format|
      if @account.present?

        if @user.account.update_with_stripe(params)
          # We saved the account, now redirect to the show page
          format.html { redirect_to user_url(@user), notice: 'Account was successfully updated.' }

        else
          @verrors = @user.account.errors.full_messages
          @account = @user.account
          @account.stripe_cc_token = @user.account.errors[:customer_id].present? ? nil :
            params[:account][:stripe_cc_token]
          @account.cardholder_name = params[:cardholder_name]
          @account.cardholder_email = params[:cardholder_email]

          format.html { render action: :edit }
        end

      else
        flash[:alert] = "We could not find the requested credit card account."
        format.html {redirect_to user_url(@user)}
      end
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

  ######################################################################
  # The missing_document method is the controller method for catching
  # a Mongoid Mongoid::Errors::DocumentNotFound exception across all
  # controller actions.
  ######################################################################
  def missing_document(exception)
	  respond_to do |format|
	    msg = "We are unable to find the requested User account - ID ##{exception.params[0]}"
  		format.html { redirect_to admin_oops_url, alert: msg }
  		format.json { head :no_content }
  	end
  end

end
