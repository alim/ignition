require 'spec_helper'

describe AccountsController do

  include_context 'user_setup'
  
  let(:find_one_user) {
    @customer = User.where(role: User::CUSTOMER).where(:account.exists => false).first
    @admin = User.where(role: User::SERVICE_ADMIN).first
    @customer_account = User.where(:account.exists => true).first
  }

  # Credit card and stripe test data
  let(:cardnum) { "4242424242424242" }
  let(:email) { "janesmith@example.com" }
  let(:name) { "Jane Smith" }
  let(:cvcvalue) { "616" }
  let(:token) { get_token(name, cardnum, Date.today.month, 
    (Date.today.year + 1), cvcvalue) }

	before(:each) {
		create_users
		create_service_admins
		create_users_with_account
		find_one_user
		signin_customer
		subject.current_user.should_not be_nil
	}
	
	after(:each) {
		delete_users
  }
 
  # NEW CHECKS ---------------------------------------------------------
  describe "New action tests" do
    
    describe "Valid examples" do
    
      it "Should return success" do
        get :new, user_id: @customer.id
        response.should be_success
      end

      it "Should use the new template" do
        get :new, user_id: @customer.id
        response.should render_template :new
      end
      
      it "Should find the correct user record" do
        get :new, user_id: @customer.id
        assigns(:user).id.should eq(@customer.id)
      end
      
      it "Should assoicate an account record" do
        get :new, user_id: @customer.id
        assigns(:account).should be_present
      end
      
    end # Valid examples
    
    describe "Invalid examples" do
       it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :new, user_id: @customer.id
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to admin_oops, if we cannot find user" do
        get :new, user_id: '99999'
        response.should redirect_to admin_oops_url
      end
      
      it "Should flash alert, if we cannot find user" do
        get :new, user_id: '99999'
        flash[:alert].should match(/We could not find the requested User account/)
      end
      
      it "Should raise a stripe error, if invalid customer id" do
        get :new, user_id: @customer_account.id
        flash[:alert].should match(/Stripe error associated with account error = No such customer/)
      end
      
      it "Should redirect to user#show, if invalid customer id" do
        get :new, user_id: @customer_account.id
        response.should redirect_to user_url(@customer_account)
      end
    end
  end # New

  # CREATE CHECKS ------------------------------------------------------
  describe "Create checks" do
   let(:account_params){
      {
        user_id: @customer.id,
			  cardholder_name: name,
			  cardholder_email: email,
			  account: {stripe_cc_token: token.id}
		  }
    }

    describe "Valid create examples" do
      it "Should return success with valid account fields" do
        post :create, account_params
        response.should redirect_to user_url(@customer)
        flash[:notice].should match(/Account was successfully created/)
      end
      
      it "Should update account customer_id" do
        post :create, account_params
        assigns(:user).account.customer_id.should be_present
      end
      
      it "Should update account cardholder name" do
        post :create, account_params
        assigns(:user).account.cardholder_name.should eq(name)
      end
      
      it "Should update account cardholder email" do
        post :create, account_params
        assigns(:user).account.cardholder_email.should eq(email)
      end
      
      it "Should update account card type" do
        post :create, account_params
        assigns(:user).account.card_type.should eq("Visa")
      end
      
      it "Should update account card last4" do
        post :create, account_params
        assigns(:user).account.last4.should eq(cardnum.split(//).last(4).join)
      end

      it "Should update account card expiration" do
        post :create, account_params
        assigns(:user).account.expiration.should eq(
          Date.today.month.to_s + '/' + (Date.today.year + 1).to_s
        )
      end   
    end # Valid create examples
    
    describe "Invalid create examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @customer
        post :create, account_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to admin_oops, if user not found" do
        params = account_params
        params[:user_id] = '9999'
        post :create, params
        response.should redirect_to admin_oops_url
      end
      
      it "Should flash an error message, if user not found" do
        params = account_params
        params[:user_id] = '9999'
        post :create, params
        flash[:alert].should match(/We could not find the requested User account/)
      end
      
      it "Should render the new template, if account could not save" do
      
        # Setup a method stub for the account method save_with_stripe
        # to return nil, which indicates a failure to save the account
        Account.any_instance.stub(:save_with_stripe).and_return(nil)
        
        post :create, account_params
        response.should render_template :new
      end
           
    end # Invalid create examples
  end # Create
  
  # EDIT ACTION TESTS --------------------------------------------------
  describe "Edit action tests" do
    let(:edit_params) {
      {
        user_id: @customer_account.id,
        id: @customer_account.account.id
      }
    }
    
    let(:customer_account_params){
      {
        user_id: @customer_account.id,
        cardholder_name: name,
        cardholder_email: email,
        account: {stripe_cc_token: token.id}
      }
    }    
    
    let(:create_customer_account) {
      post :create, customer_account_params # Create a valid account
    }
    
    describe "Valid edit action examples" do
      
      it "Should return success" do
        create_customer_account
        get :edit, edit_params
        response.should be_success
      end

      it "Should find the right User record" do
        get :edit, edit_params
        assigns(:user).id.should eq(@customer_account.id)
      end
      
      it "Should find the right Account record" do
        get :edit, edit_params
        assigns(:user).account.id.should eq(@customer_account.account.id)
      end      
      
      it "Should find the right stripe data" do
        create_customer_account
        
        get :edit, edit_params
        assigns(:user).account.cardholder_name.should eq(name)
        assigns(:user).account.cardholder_email.should eq(email)
        assigns(:user).account.last4.should be_present
        assigns(:user).account.card_type.should match(/visa/i)
      end    
    end # Valid edit action examples
    
    describe "Invalid edit action examples" do
      it "Should redirect you to sign_in, if not logged in" do
        sign_out @signed_in_user
        get :edit, edit_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to admin_oops, if account record not found" do
        params = edit_params
        params[:id] = '99999'
        get :edit, params
        response.should redirect_to admin_oops_url
      end
      
      it "Should display an alert message, if account record not found" do
        params = edit_params
        params[:id] = '99999'
        get :edit, params
        flash[:alert].should match(/We could not find the requested account for User/)
      end
      
     it "Should redirect to admin_oops, if user record not found" do
        params = edit_params
        params[:user_id] = '99999'
        get :edit, params
        response.should redirect_to admin_oops_url
      end
      
      it "Should display an alert message, if user record not found" do
        params = edit_params
        params[:user_id] = '99999'
        get :edit, params
        flash[:alert].should match(/We could not find the requested User account/)
      end
      
      it "Should raise a stripe error, if invalid customer id" do
        get :edit, edit_params
        flash[:alert].should match(/Stripe error - could not get customer data/)
      end
      
      it "Should redirect to user#show, if invalid customer id" do
        get :edit, edit_params
        response.should redirect_to user_url(@customer_account)
      end
      
    end # Invalid edit action examples
  
  end # Edit
    
  # UPDATE TESTS -------------------------------------------------------
  describe "Update tests" do
    let(:customer_account_params){
      {
        user_id: @customer_account.id,
        cardholder_name: name,
        cardholder_email: email,
        account: {stripe_cc_token: token.id}
      }
    }
    
    let(:create_customer_account){
      # Create valid account to update
      post :create, customer_account_params 
    }
    
    let(:updated_email) {"mmouse@example.com"}
    let(:updated_name) {"Mickey Mouse"}
    
    let(:update_account_params){
      {
        user_id: @customer_account.id,
        id: @customer_account.account.id, 
        cardholder_name: updated_name,
        cardholder_email: updated_email,
        account: {stripe_cc_token: get_token(updated_name, cardnum, 
          Date.today.month, (Date.today.year + 1), cvcvalue).id}
      }
    }
    
 
    describe "Valid update examples" do
      it "Should redirect to User#show path" do
        create_customer_account
        put :update, update_account_params
          
        response.should redirect_to user_url(@customer_account)
      end

      it "Should find the correct user record" do
        create_customer_account
        put :update, update_account_params
        assigns(:user).id.should eq(@customer_account.id)
      end     
      
      it "Should find the correct account record" do
        create_customer_account
        put :update, update_account_params
        assigns(:user).account.id.should eq(@customer_account.account.id)
      end       
      
      it "Should find the right stripe data" do
        create_customer_account
        put :update, update_account_params
        assigns(:user).account.cardholder_name.should eq(updated_name)
        assigns(:user).account.cardholder_email.should eq(updated_email)
        assigns(:user).account.last4.should be_present
        assigns(:user).account.card_type.should match(/visa/i)
      end            
    end # Valid update examples
    
    describe "Invalid update examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :update, update_account_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to users#index, if user not found" do
        params = update_account_params
        params[:user_id] = '99999'
        put :update, params
        response.should redirect_to users_url
      end
      
      it "Should redirect to users#index, if account not found" do
        params = update_account_params
        params[:id] = '99999'
        put :update, params
        response.should redirect_to users_url
      end      
      
      it "Should flash error message, if user not found" do
        params = update_account_params
        params[:id] = '99999'
        put :update, params
        flash[:alert].should match(/We could not find the requested User account/)
      end      
    end # Invalid update examples
  end # Update

  # DESTROY TESTS ------------------------------------------------------
  
  describe "Destroy action tests" do
    let(:destroy_params) {
      {
        user_id: @customer_account.id,
        id: @customer_account.account.id
      }
    }

    let(:customer_account_params){
      {
        user_id: @customer_account.id,
        cardholder_name: name,
        cardholder_email: email,
        account: {stripe_cc_token: token.id}
      }
    }
    
    let(:create_customer_account){
      # Create valid account to update
      post :create, customer_account_params 
    }
    
    describe "Valid examples" do
      it "Should redirect to #index" do
        create_customer_account
        delete :destroy, destroy_params
        response.should redirect_to users_url
      end

      it "Should display a success message" do
        create_customer_account
        delete :destroy, destroy_params
        flash[:notice].should match(/User credit card deleted/)
      end
      
      it "Should delete account record" do
        create_customer_account
        delete :destroy, destroy_params
        assigns(:user).account.should_not be_present
      end
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        delete :destroy, destroy_params
        response.should redirect_to new_user_session_url
      end
          
      it "Should raise an exception, if no stripe customer" do
        delete :destroy, destroy_params
        flash[:alert].should match(/Error deleting credit card account - /)
      end
      
      it "Should not delete the account record, if no stripe customer" do
        delete :destroy, destroy_params
        assigns(:user).account.should be_present
      end
      
      it "Should redirect to users#index, if no user record found" do
        params = destroy_params
        params[:user_id] = '00999'
        delete :destroy, params
        response.should redirect_to users_url
      end
      
      it "Should flash an error message, if no user record found" do
        params = destroy_params
        params[:user_id] = '00999'
        delete :destroy, params
        flash[:alert].should match(/Could not find user credit card account to delete/)      
      end
      
      it "Should redirect to users#index, if no account record found" do
        params = destroy_params
        params[:id] = '00999'
        delete :destroy, params
        response.should redirect_to users_url
      end
      
      it "Should flash an error message, if no account record found" do
        params = destroy_params
        params[:id] = '00999'
        delete :destroy, params
        flash[:alert].should match(/Could not find user credit card account to delete/)        
      end              
    end # Invalid examples
  end # Destroy action tests
end
