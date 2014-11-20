require 'spec_helper'

describe AccountsController do

  include_context 'user_setup'

  let(:customer){ User.where(role: User::CUSTOMER).where(:account.exists => false).first }
  let(:admin){ User.where(role: User::SERVICE_ADMIN).first }
  let(:customer_account){ User.where(role: User::CUSTOMER).where(:account.exists => true).first }

  # Credit card and stripe test data
  let(:cardnum) { "4242424242424242" }
  let(:email) { "janesmith@example.com" }
  let(:name) { "Jane Smith" }
  let(:cvcvalue) { "616" }
  let(:token) { get_token(name, cardnum, Date.today.month,
    (Date.today.year), cvcvalue) }


  let(:customer_account_params){
    {
      user_id: customer_account.id,
      cardholder_name: name,
      cardholder_email: email,
      account: {stripe_cc_token: token.id}
    }
  }

  let(:create_customer_account) {
    post :create, customer_account_params # Create a valid account
    customer_account.reload
  }

  let(:admin_account_params){
    {
      user_id: admin.id,
      cardholder_name: name,
      cardholder_email: email,
      account: {stripe_cc_token: token.id}
    }
  }

  let(:create_admin_account) {
    post :create, admin_account_params # Create a valid account
    admin.reload
  }


	before(:each) {
		create_users
		create_service_admins
		create_users_with_account
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
        get :new, user_id: @signed_in_user.id
        response.should be_success
      end

      it "Should use the new template" do
        get :new, user_id: @signed_in_user.id
        response.should render_template :new
      end

      it "Should find the correct user record" do
        get :new, user_id: @signed_in_user.id
        assigns(:user).id.should eq(@signed_in_user.id)
      end

      it "Should assoicate an account record" do
        get :new, user_id: @signed_in_user.id
        assigns(:account).should be_present
      end

    end # Valid examples

    describe "Invalid examples", :vcr do

      it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :new, user_id: customer.id
        response.should redirect_to new_user_session_url
      end

      it "Should redirect to admin_oops, if we cannot find user" do
        get :new, user_id: '99999'
        response.should redirect_to admin_oops_url
      end

      it "Should flash alert, if we cannot find user" do
        get :new, user_id: '99999'
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end

      it "Should raise a stripe error, if invalid customer id" do
        sign_out @signed_in_user
        sign_in customer_account
        subject.current_user.should_not be_nil

        get :new, user_id: customer_account.id
        flash[:alert].should match(/Stripe error associated with account error = No such customer/)
      end

      it "Should redirect to user#show, if invalid customer id" do
        sign_out @signed_in_user
        sign_in customer_account
        subject.current_user.should_not be_nil

        get :new, user_id: customer_account.id
        response.should redirect_to user_url(customer_account)
      end
    end

    describe "Authorization examples" do

      describe "As a customer role" do

        it "Return success for a users own record" do
          get :new, user_id: @signed_in_user.id
          response.should be_success
        end

        it "Find the requested user record owned by the user" do
          get :new, user_id: @signed_in_user.id
          assigns(:account).user.id.should eq(@signed_in_user.id)
        end

        it "Render the edit template" do
          get :new, user_id: @signed_in_user.id
          response.should render_template :new
        end

        it "Should redirect to admin_oops if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).where(:account.exists => true).first
          get :new, user_id: user.id
          response.should redirect_to admin_oops_url
        end

        it "Should flash alert if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).where(:account.exists => true).first
          get :new, user_id: user.id
          flash[:alert].should match(/You are not authorized to access the requested User./)
        end
      end # As a customer role

      describe "As a service administrator", :vcr do

        before(:each) {
          login_admin
          # @user = User.where(:id.ne => @signed_in_user.id).where(
            # :account.exists => true).first
        }

        it "Return success for a own user record" do
          get :new, user_id: @signed_in_user.id
          response.should be_success
        end

        it "Find the own user record associated with account" do
          get :new, user_id: @signed_in_user.id
          assigns(:account).user.id.should eq(@signed_in_user.id)
        end

        it "Render the new template" do
          get :new, user_id: @signed_in_user.id
          response.should render_template :new
        end

        it "Return success for a different users record" do
          create_customer_account
          get :new, user_id: customer_account.id
          response.should be_success
        end

        it "Find the requested user record assciated with account" do
          create_customer_account
          get :new, user_id: customer_account.id
          assigns(:account).user.id.should eq(customer_account.id)
        end

        it "Render the new template" do
          create_customer_account
          get :new, user_id: customer_account.id
          response.should render_template :new
        end
      end # As a service administrator
    end # New authorization examples

  end # New

  # CREATE CHECKS ------------------------------------------------------
  describe "Create checks" do
   let(:account_params){
      {
        user_id: @signed_in_user.id,
			  cardholder_name: name,
			  cardholder_email: email,
			  account: {stripe_cc_token: token.id}
		  }
    }

    let(:login_different_user) {
      sign_out @signed_in_user
      sign_in customer_account
      subject.current_user.should_not be_nil
    }

    describe "Valid create examples", :vcr do

      it "Should return success with valid account fields" do
        post :create, account_params
        response.should redirect_to user_url(@signed_in_user)
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
          token.card[:exp_month].to_s + '/' + token.card[:exp_year].to_s
        )
      end
    end # Valid create examples

    describe "Invalid create examples", :vcr do

      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
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
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end

      it "Should render the new template, if account could not save" do

        # Setup a method stub for the account method save_with_stripe
        # to return nil, which indicates a failure to save the account
        Account.any_instance.stub(:save_with_stripe).and_return(nil)

        post :create, account_params
        response.should render_template :new
      end

    end # Invalid create examples

    describe "Validation examples" do

      describe "As a customer", :vcr do

        it "Should not allow a customer to create another's account" do
          login_different_user
          post :create, account_params
          response.should redirect_to admin_oops_url
        end

        it "Should display alert when attempting to create another's account" do
          login_different_user
          post :create, account_params
          flash[:alert].should match(/You are not authorized to access the requested User/)
        end
      end # Customer examples

      describe "As an administrator", :vcr do

        let(:admin_params){
          {
            user_id: customer_account.id,
            cardholder_name: name,
            cardholder_email: email,
            account: {stripe_cc_token: token.id}
          }
        }

        it "Should flash success when creating another customers account" do
          login_admin
          post :create, admin_params
          flash[:notice].should match(/Account was successfully created/)
        end

        it "Should redirect to user_url when creating another customers account" do
          login_admin
          post :create, admin_params
          response.should redirect_to user_url(customer_account)
        end

      end # Admin examples
    end # Create validation examples
  end # Create

  # EDIT ACTION TESTS --------------------------------------------------
  describe "Edit action tests" do
    let(:edit_params) {
      {
        user_id: customer_account.id,
        id: customer_account.account.id
      }
    }

    before(:each){
      sign_out @signed_in_user
      sign_in customer_account
      subject.current_user.should_not be_nil
    }

    describe "Valid edit action examples", :vcr do

      it "Should return success" do
        create_customer_account
        get :edit, edit_params
        response.should be_success
      end

      it "Should find the right User record" do
        create_customer_account
        get :edit, edit_params
        assigns(:user).id.should eq(customer_account.id)
      end

      it "Should find the right Account record" do
        create_customer_account
        get :edit, edit_params
        assigns(:user).account.id.should eq(customer_account.account.id)
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

    describe "Invalid edit action examples", :vcr do

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
        flash[:alert].should match(/We could not find the requested credit card account/)
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
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end

      it "Should raise a stripe error, if invalid customer id" do
        get :edit, edit_params
        flash[:alert].should match(/Stripe error - could not get customer data/)
      end

      it "Should redirect to user#show, if invalid customer id" do
        get :edit, edit_params
        response.should redirect_to user_url(customer_account)
      end

    end # Invalid edit action examples

    describe "Authorization examples" do

      describe "As a customer role", :vcr do

        it "Return success for a users own record" do
          create_customer_account
          get :edit, edit_params
          response.should be_success
        end

        it "Find the requested user record owned by the user" do
          create_customer_account
          get :edit, edit_params
          assigns(:user).id.should eq(customer_account.id)
        end

        it "Render the edit template" do
          create_customer_account
          get :edit, edit_params
          response.should render_template :edit
        end

        it "Should redirect to admin_oops if user requests another's record" do
          create_customer_account
          user = User.where(:id.ne => customer_account.id).first
          edit_params[:user_id] = user.id
          get :edit, edit_params
          response.should redirect_to admin_oops_url
        end

        it "Should flash alert if user requests another's record" do
          create_customer_account
          user = User.where(:id.ne => customer_account.id).first
          edit_params[:user_id] = user.id
          get :edit, edit_params
          flash[:alert].should match(/You are not authorized to access the requested/)
        end
      end # As a customer role

      describe "As a service administrator", :vcr do

        before(:each) {
          login_admin
        }

        it "Return success for another users record" do
          create_customer_account
          get :edit, edit_params
          response.should be_success
        end

        it "Find the requested user record owned by another user" do
          create_customer_account
          get :edit, edit_params
          assigns(:user).id.should eq(customer_account.id)
        end

        it "Render the edit template" do
          create_customer_account
          get :edit, edit_params
          response.should render_template :edit
        end

        it "Return success for admin users record" do
          create_admin_account

          get :edit, {user_id: admin.id, id: admin.account.id}
          response.should be_success
        end

        it "Find the requested user record owned by admin user" do
          create_admin_account
          get :edit, {user_id: admin.id, id: admin.account.id}
          assigns(:user).id.should eq(admin.id)
        end

        it "Render the edit template" do
          create_admin_account
          get :edit, {user_id: admin.id, id: admin.account.id}
          response.should render_template :edit
        end

      end # As a service administrator
    end # Edit authorization examples

  end # Edit

  # UPDATE TESTS -------------------------------------------------------
  describe "Update tests" do

    let(:updated_email) {"mmouse@example.com"}
    let(:updated_name) {"Mickey Mouse"}

    let(:update_account_params){
      {
        user_id: customer_account.id,
        id: customer_account.account.id,
        cardholder_name: updated_name,
        cardholder_email: updated_email,
        account: {stripe_cc_token: get_token(updated_name, cardnum,
          Date.today.month, (Date.today.year + 1), cvcvalue).id}
      }
    }

    before(:each){
      sign_out @signed_in_user
      sign_in customer_account
      subject.current_user.should_not be_nil
    }

    describe "Valid update examples", :vcr do

      it "Should redirect to User#show path" do
        create_customer_account
        put :update, update_account_params

        response.should redirect_to user_url(customer_account)
      end

      it "Should find the correct user record" do
        create_customer_account
        put :update, update_account_params
        assigns(:user).id.should eq(customer_account.id)
      end

      it "Should find the correct account record" do
        create_customer_account
        put :update, update_account_params
        assigns(:user).account.id.should eq(customer_account.account.id)
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

    describe "Invalid update examples", :vcr do

      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :update, update_account_params
        response.should redirect_to new_user_session_url
      end

      it "Should redirect to admin_oops_url, if user not found" do
        params = update_account_params
        params[:user_id] = '99999'
        put :update, params
        response.should redirect_to admin_oops_url
      end

      it "Should redirect to admin_oops_url, if account not found" do
        params = update_account_params
        params[:id] = '99999'
        put :update, params
        response.should redirect_to user_url(customer_account)
      end

      it "Should flash error message, if user not found" do
        params = update_account_params
        params[:id] = '99999'
        put :update, params
        flash[:alert].should match(/We could not find the requested credit card account./)
      end
    end # Invalid update examples

   describe "Authorization examples" do

      describe "As a customer role", :vcr do

        it "Return success for a users own record" do
          create_customer_account
          put :update, update_account_params
          response.should redirect_to user_url(assigns(:user))
        end

        it "Find the requested user record owned by the user" do
          create_customer_account
          put :update, update_account_params
          assigns(:user).id.should eq(customer_account.id)
        end

        it "Flash success message after update" do
          create_customer_account
          put :update, update_account_params
          flash[:notice].should match(/Account was successfully updated./)
        end

        it "Should redirect to admin_oops if user requests another's record" do
          user = User.where(:id.ne => customer_account.id).where(
            :account.exists => true).first
          update_account_params[:user_id] = user.id
          update_account_params[:id] = user.account.id
          put :update, update_account_params
          response.should redirect_to admin_oops_url
        end

        it "Should flash alert if user requests another's record" do
          user = User.where(:id.ne => customer_account.id).where(
            :account.exists => true).first
          update_account_params[:user_id] = user.id
          update_account_params[:id] = user.account.id
          put :update, update_account_params
          flash[:alert].should match(/You are not authorized to access the requested/)
        end

      end # As a customer role

      describe "As a service administrator", :vcr do

        before(:each) {
          login_admin
        }

        it "Should redirect to show view for a users own record" do
          create_admin_account
          update_account_params[:user_id] = admin.id
          update_account_params[:id] = admin.account.id
          put :update, update_account_params
          response.should redirect_to user_url(assigns(:user))
        end

        it "Find the requested user record owned by the user" do
          create_admin_account
          update_account_params[:user_id] = admin.id
          update_account_params[:id] = admin.account.id
          put :update, update_account_params
          assigns(:user).id.should eq(admin.id)
        end

        it "Return success for another users record" do
          create_customer_account
          put :update, update_account_params
          response.should redirect_to user_url(assigns(:user))
        end

        it "Find the requested user record owned by another user" do
          create_customer_account
          put :update, update_account_params
          assigns(:user).id.should eq(customer_account.id)
        end

        it "Flash success message after update" do
          create_customer_account
          put :update, update_account_params
          flash[:notice].should match(/Account was successfully updated./)
        end

      end # As a service administrator
    end # Authorization examples for update

  end # Update

  # DESTROY TESTS ------------------------------------------------------

  describe "Destroy action tests" do
    let(:destroy_params) {
      {
        user_id: customer_account.id,
        id: customer_account.account.id
      }
    }


    before(:each) {
      sign_out @signed_in_user
      sign_in customer_account
      subject.current_user.should_not be_nil
    }

    describe "Valid examples", :vcr do

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
        customer_account.reload
        customer_account.account.should_not be_present
      end
    end # Valid examples

    describe "Invalid examples", :vcr do

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
        destroy_params[:user_id] = '00999'
        delete :destroy, destroy_params
        response.should redirect_to admin_oops_url
      end

      it "Should flash an error message, if no user record found" do
        destroy_params[:user_id] = '00999'
        delete :destroy, destroy_params
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end

      it "Should redirect to users#index, if no account record found" do
        destroy_params[:id] = '00999'
        delete :destroy, destroy_params
        response.should redirect_to user_url(customer_account)
      end

      it "Should flash an error message, if no account record found" do
        destroy_params[:id] = '00999'
        delete :destroy, destroy_params
        flash[:alert].should match(/Could not find user credit card account to delete./)
      end
    end # Invalid examples

    describe "Authorization examples" do
      describe "As a customer role", :vcr do

        before(:each) {
          create_customer_account
          destroy_params[:user_id] = customer_account.id
          destroy_params[:id] = customer_account.account.id

          customer = User.where(:id.ne => customer_account.id).where(:role => User::CUSTOMER).first
          sign_out customer_account
          sign_in customer
          subject.current_user.should_not be_nil
        }

        it "Should redirect to admin_oops if attempting to delete other user account" do
          delete :destroy, destroy_params
          response.should redirect_to admin_oops_url
        end

        it "Should flash an alert message if attempting to delete other user account" do
          delete :destroy, destroy_params
          flash[:alert].should match(/You are not authorized to access the requested/)
        end
      end # As a customer role

      describe "As a administrator role", :vcr do

        before(:each) {
          login_admin
        }

        let(:admin_destroy_params) {
          {
            user_id: admin.id,
            id: admin.account.id
          }
        }

        it "Should redirect to users_url, when deleting their own account" do
          create_admin_account
          delete :destroy, admin_destroy_params
          response.should redirect_to users_url
        end

        it "Should delete the account, when deleting their own account" do
          create_admin_account
          admin.account.should_not be_nil
          delete :destroy, admin_destroy_params
          admin.reload
          admin.account.should be_nil
        end

        it "Should flash success notice, when deleting their own account" do
          create_admin_account
          delete :destroy, admin_destroy_params
          flash[:notice].should match(/User credit card deleted./)
        end

        it "Should be able to delete another user's account" do
          create_customer_account
          delete :destroy, destroy_params
          customer_account.reload
          customer_account.account.should be_nil
        end

        it "Should be redirected to users_url, when deleting another user's account" do
          create_customer_account
          delete :destroy, destroy_params
          response.should redirect_to users_url
        end

        it "Should be flash notice to users_url, when deleting another user's account" do
          create_customer_account
          delete :destroy, destroy_params
          flash[:notice].should match(/User credit card deleted./)
        end

      end # Administration role
    end # Authorization examples for delete
  end # Destroy action tests
end
