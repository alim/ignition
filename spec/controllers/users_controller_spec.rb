require 'spec_helper'

describe UsersController do
	include_context 'user_setup'

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
				response.should render_template("index")
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
  	  
  	  it "Should not redirect to sign in, if not signed in" do
  	    sign_out @user
  	    get :index
  	    response.should redirect_to new_user_session_url
  	  end
  	end # Other index test cases
  	
  end # Index tests
end
