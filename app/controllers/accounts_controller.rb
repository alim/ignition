class AccountsController < ApplicationController
  # Before filters -----------------------------------------------------
  before_filter :authenticate_user!
  
  before_action :set_user
  
  ######################################################################
  # GET    /admin/users/:user_id/accounts/new(.:format)
  #
  # The new action will present a AJAX based form to user as part of
  # the User views. If there is an error it will redirect to the 
  # admin_oops_url with a corresponding error message.
  ######################################################################
  def new
    respond_to do |format|
      if @user.present? 
        begin
          @user.account = Account.new
          @user.reload
          @account = @user.account
        	format.html
      	rescue Stripe::StripeError => stripe_error
          flash[:alert] = "Stripe error associated with account error = #{stripe_error.message}"
          format.html {redirect_to user_url(@user)}
        end
      else
        flash[:alert] = "We could not find the requested User account ##{params[:user_id]}"
        format.html {redirect_to admin_oops_url}
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
      if @user.present?
                
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
        
      else
        flash[:alert] = "We could not find the requested User account ##{params[:user_id]}"
        format.html {redirect_to admin_oops_url}
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
      if @user.present? 
        if @account.present?
          if @account.get_customer
            format.html
          else
            flash[:alert] = "Stripe error - could not get customer data."
            format.html {redirect_to user_url(@user)}
          end
        else
          flash[:alert] = "We could not find the requested account for User ##{params[:user_id]}"
          format.html {redirect_to admin_oops_url}
        end
      else
        flash[:alert] = "We could not find the requested User account ##{params[:user_id]}"
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
      if @user.present? && @account.present?

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
        flash[:alert] = "We could not find the requested User account ##{params[:user_id]}"
        format.html {redirect_to users_url}
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
    if @user.present? && @account.present?
      begin
        @user.account.destroy
        @user.reload
        redirect_to users_url, notice: "User credit card deleted."
      rescue Stripe::StripeError => stripe_error
        flash[:alert] = "Error deleting credit card account - #{stripe_error.message}"
        redirect_to users_url
      end
    else
      flash[:alert] = "Could not find user credit card account to delete."
      redirect_to users_url
    end  
  end
  
  
  # PROTECTED INSTANCE METHODS =----------------------------------------
  protected
  
  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_user
    begin
      @user = User.find(params[:user_id])
   
      if @user.account.present? && @user.account.id.to_s == params[:id]
        @account = @user.account 
      else
        @account = nil
      end
    rescue Mongoid::Errors::DocumentNotFound
      @user = nil
    end
  end

  
end
