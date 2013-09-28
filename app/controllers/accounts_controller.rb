class AccountsController < ApplicationController
  # Before filters -----------------------------------------------------
  before_filter :authenticate_user!
  
  before_action :set_user
  
  ######################################################################
  # The new action will present a AJAX based form to user as part of
  # the User views. If there is an error it will redirect to the 
  # admin_oops_url with a corresponding error message.
  ######################################################################
  def new
    respond_to do |format|
      if @user.present? 
        @user.account = Account.new
        @user.reload
        @account = @user.account
      	format.html
      else
        flash[:alert] = "We could not find the requested User account ##{params[:user_id]}"
        format.html {redirect_to admin_oops_url}
      end
    end
  end
  
  ######################################################################
  # The create method will update the account settings with the 
  # stripe.com customer_id and set the status of the account to ACTIVE
  ######################################################################
  def create
    respond_to do |format|
      if @user.account.save_with_stripe(params, current_user)
        
	      # We saved the account, now redirect to the show page
        format.html { redirect_to user_url(@user), notice: 'Account was successfully created.' }

      else
	      @verrors = @user.account.errors.full_messages
        @account = @user.account
	      @account.stripe_cc_token = @user.account.errors[:customer_id].present? ? nil :
		      params[:account][:stripe_cc_token]

	      @account.cardholder_name = params[:cardholder_name]
	      @account.cardholder_email = params[:cardholder_email]

        format.html { render action: "new" }

      end
    end
  end
  
  # PROTECTED INSTANCE METHODS =----------------------------------------
  
  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_user
    begin
      @user = User.find(params[:user_id])
    rescue Mongoid::Errors::DocumentNotFound
      @user = nil
    end
  end

  
end
