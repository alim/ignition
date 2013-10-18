require 'spec_helper'

describe UsersController do
	include_context 'user_setup'

  let(:find_one_user) {
    @customer = User.where(role: User::CUSTOMER).first
    @admin = User.where(role: User::SERVICE_ADMIN).first
  }

  let(:login_customer) {
    sign_out @signed_in_user
    signin_customer
  } 

	before(:each) {
		create_users
		create_service_admins
	}
	
	after(:each) {
		delete_users
  }
  
	# DEVISE CHECK -------------------------------------------------------
	it "should be signed in with a current_user" do
		signin_admin
		subject.current_user.should_not be_nil
		subject.current_user.role.should eq(User::SERVICE_ADMIN)
	end
  
  # INDEX TEXTS --------------------------------------------------------
  describe "Index action examples" do
  
    before(:each) {
      # Signing in as service admin, since index action is restricted
			signin_admin   
			subject.current_user.should_not be_nil
  	}
  
  	describe "Valid result tests" do
  		  	
  		it "Should return sucess" do
				get :index
				response.should be_success
  		end
  		  	
  		it "Should find all available records with no search criteria" do
				get :index
				assigns(:users).count.should eq(User.count)
  		end
  		
 			it "should set the menu active flag for admin menu" do
				get :index
				assigns(:users_active).should eq("class=active")
			end
			
			it "should render index template" do	
				get :index
				response.should render_template :index
			end	
			
			describe "Search by email address" do
				it "Should return success for a single record exact match" do
					user = User.first
					get :index, {search: user.email, stype: 'email'}
					response.should be_success
				end
				
				it "Should return a single record for exact match" do
					user = User.first
					get :index, {search: user.email, stype: 'email'}
					assigns(:users).count.should eq(1)
				end
				
				it "Should return all records for emtpy email" do
					user = User.first
					get :index, {search: nil, stype: 'email'}
					assigns(:users).count.should eq(User.count)
				end		
				
        it "Should return no records for non-matching email" do
					get :index, {search: "Mickey Mouse", stype: 'email'}
					assigns(:users).count.should eq(0)
				end												
			end
			
			describe "Search by first_name address" do
				it "Should return success for a single record exact match" do
					user = User.first
					get :index, {search: user.first_name, stype: 'first_name'}
					response.should be_success
				end
				
				it "Should return a single record for exact match" do
					user = User.first
					get :index, {search: user.first_name, stype: 'first_name'}
					assigns(:users).count.should eq(1)
				end
				
				it "Should return all records for emtpy first_name" do
					user = User.first
					get :index, {search: nil, stype: 'first_name'}
					assigns(:users).count.should eq(User.count)
				end
				
        it "Should return no records for non-matching first_name" do
					get :index, {search: "Mickey Mouse", stype: 'first_name'}
					assigns(:users).count.should eq(0)
				end	
										
			end
			
			describe "Search by last_name address" do
				it "Should return success for a single record exact match" do
					user = User.first
					get :index, {search: user.last_name, stype: 'last_name'}
					response.should be_success
				end
				
				it "Should return a single record for exact match" do
					user = User.first
					get :index, {search: user.last_name, stype: 'last_name'}
					assigns(:users).count.should eq(1)
				end
				
				it "Should return all records for emtpy last_name" do
					user = User.first
					get :index, {search: nil, stype: 'last_name'}
					assigns(:users).count.should eq(User.count)
				end	
				
        it "Should return no records for non-matching last_name" do
					get :index, {search: "Mickey Mouse", stype: 'last_name'}
					assigns(:users).count.should eq(0)
				end												
			end
			
			describe "Search by customer role" do
			  before(:each) {
			    create_service_admins
			  }
			  
			  describe "No other search criteria - roll only search" do
			    it "Should return success" do
			      get :index, {role_filer: 'customer'}
			      response.should be_success
			    end

			    it "Should find all customer records" do
			      get :index, {role_filter: 'customer'}
			      
			      users = User.where(role: User::CUSTOMER)
			      assigns(:users).count.should eq(users.count)
			    end

			    it "Should find all admin records" do
			      get :index, {role_filter: 'service_admin'}
			      
			      users = User.where(role: User::SERVICE_ADMIN)
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find all records, when specifying both rolls" do
			      get :index, {role_filter: 'both'}
			      
			      users = User.all
			      assigns(:users).count.should eq(users.count)
			    end
			  end
			  
			  describe "Search and roll criteria" do
			    it "Should find all matching email and customer roll records" do
			      users = User.where(role: User::CUSTOMER).by_email("Person")
			      
			      get :index, { search: "Person", stype: 'email', 
			        role_filter: 'customer' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find single matching email and customer roll record" do
			      user = User.where(role: User::CUSTOMER).last
			      
			      get :index, { search: user.email, stype: 'email', 
			        role_filter: 'customer' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(1)
			      assigns(:users).first.id.should eq(user.id)
			    end

			    it "Should find all matching email and admin roll records" do
			      users = User.where(role: User::SERVICE_ADMIN).by_email("Person")
			      
			      get :index, { search: "Person", stype: 'email', 
			        role_filter: 'service_admin' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find single matching email and admin roll record" do
			      user = User.where(role: User::SERVICE_ADMIN).first
			      
			      get :index, { search: user.email, stype: 'email', 
			        role_filter: 'service_admin' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(1)
			      assigns(:users).first.id.should eq(user.id)
			    end

			    it "Should find all matching email and both rolls records" do
			      users = User.by_email("Person")
			      
			      get :index, { search: "Person", stype: 'email', 
			        role_filter: 'both' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find single matching email and both rolls" do
			      user = User.last
			      
			      get :index, { search: user.email, stype: 'email', 
			        role_filter: 'both' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(1)
			      assigns(:users).first.id.should eq(user.id)
			    end

          it "Should find all matching first_name and customer roll records" do
			      users = User.where(role: User::CUSTOMER).by_first_name("John")
			      
			      get :index, { search: "John", stype: 'first_name', 
			        role_filter: 'customer' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find single matching email and customer roll record" do
			      user = User.where(role: User::CUSTOMER).last
			      
			      get :index, { search: user.first_name, stype: 'first_name', 
			        role_filter: 'customer' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(1)
			      assigns(:users).first.id.should eq(user.id)
			    end

			    it "Should find all matching last_name and admin roll records" do
			      users = User.where(role: User::SERVICE_ADMIN).by_last_name("Smith")
			      
			      get :index, { search: "Smith", stype: 'last_name', 
			        role_filter: 'service_admin' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    
			    it "Should find single matching last_name and admin roll record" do
			      user = User.where(role: User::SERVICE_ADMIN).first
			      
			      get :index, { search: user.last_name, stype: 'last_name', 
			        role_filter: 'service_admin' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(1)
			      assigns(:users).first.id.should eq(user.id)
			    end
			    
			    it "Should find all matching last_name and both role records" do
			      users = User.by_last_name("Smith")
			      
			      get :index, { search: "Smith", stype: 'last_name', 
			        role_filter: 'both' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    			    
			    it "Should find all matching first_name and both role records" do
			      users = User.by_first_name("John")
			      
			      get :index, { search: "John", stype: 'first_name', 
			        role_filter: 'both' }
			      
			      assigns(:users).should_not be_empty
			      assigns(:users).count.should eq(users.count)
			    end
			    			    
			  end # Search and roll			  
			end	# Search by customer roll
  	end # Valid tests
  	
  	describe "Other #Index test cases" do
  	  it "Should redirect to sign in, if no users" do
  	    User.destroy_all
  	    get :index
  	    response.should be_success
  	    assigns(:users).count.should eq(0)
  	  end
  	  
  	  it "Should redirect to sign in, if not signed in" do
  	    sign_out @signed_in_user
  	    get :index
  	    response.should redirect_to new_user_session_url
  	  end
  	end # Other index test cases
  	
    describe "Authorization examples" do  

      it "Should redirect to admin_oops as a customer" do
        login_customer
        get :index
        response.should redirect_to admin_oops_url
      end
       
    end # Index authorization  	
  	
  end # Index tests
  
  # SHOW TESTS ---------------------------------------------------------
  describe "Show action tests" do
    
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
			find_one_user
  	}
  	
    describe "Valid examples" do
      
      it "Should return with success" do
        get :show, {id: @customer.id }
        response.should be_success
      end
      
      it "Should use the show template" do
        get :show, {id: @customer.id }
        response.should render_template :show
      end
      
      it "Should find matching user record" do
        get :show, {id: @customer.id }
        assigns(:user).id.should eq(@customer.id)
      end
      
      it "Should be able to show an admin user record" do
        get :show, {id: @admin.id }
        assigns(:user).id.should eq(@admin.id)
      end
            
    end # Valid show examples
    
    describe "Invalid examples" do
      it "Should not succeed, if not logged in" do
        sign_out @signed_in_user
        get :show, {id: @admin.id }
        response.should_not be_success
      end
      
      it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :show, {id: @admin.id }
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to admin_oops_url, if record not found" do
        get :show, {id: '99999'}
        response.should redirect_to admin_oops_url
      end
      
      it "Should flash an alert message, if record not found" do
        get :show, {id: '99999'}
        flash[:alert].should match(/^We are unable to find the requested User - ID/)
      end      
    end

    describe "Authorization examples" do  
    
      describe "As a customer role" do
      
        before(:each) {
          login_customer
        }
        
        it "Return success for a users own record" do
          get :show, {id: @signed_in_user.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by the user" do
          get :show, {id: @signed_in_user.id}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
        
        it "Render the show template" do
          get :show, {id: @signed_in_user.id}
          response.should render_template :show
        end
        
        it "Should redirect to admin_oops if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          get :show, {id: user.id}
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash alert if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          get :show, {id: user.id}
          flash[:alert].should match(/You are not authorized to access the requested/)
        end        
      end # As a customer role
      
      describe "As a service administrator" do
        before(:each) {
          # current signed_in user is a service admin
          @user_record = User.where(:id.ne => @signed_in_user.id).first
        }
        
        it "Return success for a users own record" do
          get :show, {id: @signed_in_user.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by the user" do
          get :show, {id: @signed_in_user.id}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
        
        it "Render the show template" do
          get :show, {id: @signed_in_user.id}
          response.should render_template :show
        end 
        
        it "Return success for another users record" do
          get :show, {id: @user_record.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by another user" do
          get :show, {id: @user_record.id}
          assigns(:user).id.should eq(@user_record.id)
        end 
        
        it "Render the show template" do
          get :show, {id: @user_record.id}
          response.should render_template :show
        end          

      end # As a service administrator    
    end # Show authorization examples    
    
  end # Show action
  
  # NEW TESTS ----------------------------------------------------------
  describe "New tests" do
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
  	}
  	
    describe "Valid examples" do
      
      it "Should return success" do
        get :new
        response.should be_success
      end
      
      it "Should use the new template" do
        get :new
        response.should render_template :new
      end
      
      it "Set a random passowrd" do
        get :new
        assigns(:user).password.should be_present
      end
      
      it "Random passowrd and confirmation should match" do
        get :new
        assigns(:user).password.should eq(assigns(:user).password_confirmation)
      end
    end # Valid examples
    
    describe "Invalid examples" do
    
       it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :new
        response.should redirect_to new_user_session_url
      end
      
    end # Invalid examples
  
    describe "Authorization examples" do
      
      before(:each) {
        login_customer
      }
      
      describe "Customer login" do
        it "Should redirect to admin_oops" do
          get :new
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash an alert message" do
          get :new
          flash[:alert].should match(/You are not authorized to access the requested/)
        end
      end
    end # Authorization examples
  end # New tests
  
  # CREATE TESTS -------------------------------------------------------
  describe "Create tests" do
    let(:new_account_params){
      { user: 
        {
          email: "mickey_mouse@example.com",
          first_name: "Mickey",
          last_name: "Mouse",
          phone: "734.555.1212",
          password: "somepassword",
          password_confirmation: "somepassword"
        }
      }
    }
  
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
  	}
  	
    describe "Valid examples" do
      
      it "Should create a new record with matching attributes" do      
        post :create, new_account_params
        assigns(:user).should be_present
      end
      
      it "Should redirect to show new record" do
        post :create, new_account_params
        response.should redirect_to user_url(assigns(:user))
      end
      
      it "Should increase the number of User records by 1" do
        expect {
          post :create, new_account_params
        }.to change(User, :count).by(1)
      end
      
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should not create a new User, if not logged in" do
        sign_out @signed_in_user
         expect {
          post :create, new_account_params
        }.to change(User, :count).by(0)
      end
      
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        post :create, new_account_params
        response.should redirect_to redirect_to new_user_session_url
      end
      
      it "Should show a validation error if missing email" do
        params = new_account_params
        params[:user][:email] = nil
        post :create, params
        assigns(:verrors)[0].should match(/Email can't be blank/)
      end
      
      it "Should show a validation error if missing first_name" do
        params = new_account_params
        params[:user][:first_name] = nil
        post :create, params
        assigns(:verrors)[0].should match(/First name can't be blank/)
      end
      
      it "Should show a validation error if missing last_name" do
        params = new_account_params
        params[:user][:last_name] = nil
        post :create, params
        assigns(:verrors)[0].should match(/Last name can't be blank/)
      end
      
      it "Should show a validation error if missing phone" do
        params = new_account_params
        params[:user][:phone] = nil
        post :create, params
        assigns(:verrors)[0].should match(/Phone can't be blank/)
      end
      
      it "Should show a validation error if missing role" do
        params = new_account_params
        params[:user][:role] = nil
        post :create, params
        assigns(:verrors)[0].should match(/Role is invalid/)
      end      
    end # Invalid examples
  
    describe "Authorization examples" do
      
      before(:each) {
        login_customer
      }
      
      describe "Customer login" do
        it "Should redirect to admin_oops" do
          post :create, new_account_params
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash an alert message" do
          post :create, new_account_params
          flash[:alert].should match(/You are not authorized to access the requested/)
        end
      end
    end # Authorization examples
  
  end # Create tests
  
  # EDIT TESTS ---------------------------------------------------------
  describe "Edit tests" do
  
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
			find_one_user
  	}
  	

    describe "Valid examples" do 
      
      it "Should return success" do
        get :edit, {id: @customer.id}
        response.should be_success
      end
      
      it "Should find the correct User record" do
        get :edit, {id: @customer.id}
        assigns(:user).id.should eq(@customer.id)
      end
      
    end # Valid examples
    
    describe "Invalid examples" do
    
      it "Should redirect you to sign_in, if not logged in" do
        sign_out @signed_in_user
        get :edit, {id: @customer.id}
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to admin_oops_url, if record not found" do
        get :edit, {id: '99999'}
        response.should redirect_to admin_oops_url
      end
      
      it "Should display an alert message, if record not found" do
        get :edit, {id: '99999'}
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end
      
    end # Invalid examples
    
    describe "Authorization examples" do  
    
      describe "As a customer role" do
      
        before(:each) {
          login_customer
        }
        
        it "Return success for a users own record" do
          get :edit, {id: @signed_in_user.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by the user" do
          get :edit, {id: @signed_in_user.id}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
        
        it "Render the edit template" do
          get :edit, {id: @signed_in_user.id}
          response.should render_template :edit
        end
        
        it "Should redirect to admin_oops if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          get :edit, {id: user.id}
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash alert if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          get :edit, {id: user.id}
          flash[:alert].should match(/You are not authorized to access the requested/)
        end        
      end # As a customer role
      
      describe "As a service administrator" do
        before(:each) {
          # current signed_in user is a service admin
          @user_record = User.where(:id.ne => @signed_in_user.id).first
        }
        
        it "Return success for a users own record" do
          get :edit, {id: @signed_in_user.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by the user" do
          get :edit, {id: @signed_in_user.id}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
        
        it "Render the edit template" do
          get :edit, {id: @signed_in_user.id}
          response.should render_template :edit
        end 
        
        it "Return success for another users record" do
          get :edit, {id: @user_record.id}
          response.should be_success
        end
        
        it "Find the requested user record owned by another user" do
          get :edit, {id: @user_record.id}
          assigns(:user).id.should eq(@user_record.id)
        end 
        
        it "Render the edit template" do
          get :edit, {id: @user_record.id}
          response.should render_template :edit
        end          

      end # As a service administrator    
    end # Edit authorization examples        
    
  end # Edit tests
  
  # UPDATE TESTS -------------------------------------------------------
  
  describe "Update tests" do
  
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
			find_one_user
  	}
  
    let(:update_account_params){
      {
        email: "mickey_mouse@example.com",
        first_name: "Mickey",
        last_name: "Mouse",
        phone: "734.555.1212",
        password: "somepassword",
        password_confirmation: "somepassword",
        role: User::SERVICE_ADMIN
      }
    }
  	
    describe "Valid examples" do
    
      it "Should find the appropriate User account" do
        put :update, {id: @customer.id, user: update_account_params}
        assigns(:user).id.should eq(@customer.id)
      end
    
      it "Should redirect to showing the updated record" do
        put :update, {id: @customer.id, user: update_account_params}
        response.should redirect_to user_url(@customer)
      end
      
      it "Should update the user account attributes" do
        put :update, {id: @customer.id, user: update_account_params}
        params = update_account_params
        assigns(:user).email.should eq(params[:email])
        assigns(:user).first_name.should eq(params[:first_name])
        assigns(:user).last_name.should eq(params[:last_name])
        assigns(:user).phone.should eq(params[:phone])
        assigns(:user).role.should eq(params[:role])
      end
      
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :update, {id: @customer.id, user: update_account_params}
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to #index, if user not found" do
        put :update, {id: '99999', user: update_account_params}
        response.should redirect_to admin_oops_url
      end
      
      it "Should flash error message, if user not found" do
        put :update, {id: '99999', user: update_account_params}
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end      
    end # Invalid examples

   describe "Authorization examples" do  
    
      describe "As a customer role" do
      
        before(:each) {
          login_customer
        }
        
        it "Return success for a users own record" do
          put :update, {id: @signed_in_user.id, user: update_account_params}
          response.should redirect_to user_url(assigns(:user))
        end
        
        it "Find the requested user record owned by the user" do
          put :update, {id: @signed_in_user.id, user: update_account_params}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
               
        it "Flash success message after update" do
          put :update, {id: @signed_in_user.id, user: update_account_params}
          flash[:notice].should match(/User account succesfully updated/)
        end 
                
        it "Should redirect to admin_oops if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          put :update, {id: user.id, user: update_account_params}
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash alert if user requests another's record" do
          user = User.where(:id.ne => @signed_in_user.id).first
          put :update, {id: user.id, user: update_account_params}
          flash[:alert].should match(/You are not authorized to access the requested/)
        end    
            
      end # As a customer role
      
      describe "As a service administrator" do
        before(:each) {
          # current signed_in user is a service admin
          @user_record = User.where(:id.ne => @signed_in_user.id).first
        }
        
        it "Return success for a users own record" do
          put :update, {id: @signed_in_user.id, user: update_account_params}
          response.should redirect_to user_url(assigns(:user))
        end
        
        it "Find the requested user record owned by the user" do
          put :update, {id: @signed_in_user.id, user: update_account_params}
          assigns(:user).id.should eq(@signed_in_user.id)
        end 
        
        it "Return success for another users record" do
          put :update, {id: @user_record.id, user: update_account_params}
          response.should redirect_to user_url(assigns(:user))
        end
        
        it "Find the requested user record owned by another user" do
          put :update, {id: @user_record.id, user: update_account_params}
          assigns(:user).id.should eq(@user_record.id)
        end 
        
        it "Flash success message after update" do
          put :update, {id: @user_record.id, user: update_account_params}
          flash[:notice].should match(/User account succesfully updated/)
        end          

      end # As a service administrator  
    end # Authorization examples for update
  
  end # Update tests
  
  # DESTROY TESTS ------------------------------------------------------
  describe "Destroy tests" do
    let(:destroy_user){
        @destroy_user = User.where(:id.ne => @signed_in_user.id).first
    }
    
    before(:each) {
			signin_admin
			subject.current_user.should_not be_nil
			destroy_user
  	}
  	
    describe "Valid examples" do
      
      it "Should redirect to #index" do
        delete :destroy, {id: @destroy_user.id}      
        response.should redirect_to users_url
      end

      it "Should display a success message" do
        delete :destroy, {id: @destroy_user.id}
        flash[:notice].should match(/User account/)
      end
      
      it "Should reduce the number of user accounts by 1" do
        expect {
          delete :destroy, {id: @destroy_user.id}
        }.to change(User, :count).by(-1)
      end
       
    end
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        delete :destroy, {id: @destroy_user.id}
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to #index, if user not found" do
        delete :destroy, {id: '99999'}
        response.should redirect_to admin_oops_url
      end
      
      it "Should flash an error message, if user not found" do
        delete :destroy, {id: '99999'}
        flash[:alert].should match(/We are unable to find the requested User - ID/)
      end   
    end # Invalid examples
    
    describe "Authorization examples" do  
    
      describe "As a customer role" do
        before(:each) {
          login_customer
        }
        
        it "Should redirect to admin_oops" do
          delete :destroy, {id: @destroy_user.id}
          response.should redirect_to admin_oops_url
        end
        
        it "Should flash an alert message" do
          delete :destroy, {id: @destroy_user.id}
          flash[:alert].should match(/You are not authorized to access the requested/)
        end
            
      end # As a customer role
 
    end # Authorization examples for delete    
    
  end # Delete tests
end
