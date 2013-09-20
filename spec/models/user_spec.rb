require 'spec_helper'

describe User do
	include_context 'user_setup'
	
	before(:each) {
		create_users
	}
	
	after(:each) {
		delete_users
  }
  
  # METHOD CHECKS ------------------------------------------------------
	describe "Should respond to all accessor methods" do
		it { should respond_to(:email) }
		it { should respond_to(:password) }
		it { should respond_to(:password_confirmation) }
		it { should respond_to(:remember_me) }
		it { should respond_to(:first_name) }
		it { should respond_to(:last_name) }
		it { should respond_to(:phone) }
		it { should respond_to(:authentication_token) }
		it { should respond_to(:role) }
		it { should respond_to(:role_str) }
	end
	
	# ACCESSOR TESTS -----------------------------------------------------
	describe "First name examples" do
		let(:get_first_name) {
			@user = User.first
			@first_name = @user.first_name
		}
		
		it "Should strip extra trailing spaces" do
			get_first_name			
			@user.first_name = @first_name + '    	    '
			@user.save
			
			@user.first_name.should eq(@first_name)
		end
		
		it "Should strip extra leading spaces" do
			get_first_name			
			@user.first_name = '    	    ' + @first_name 	
			@user.save
			
			@user.first_name.should eq(@first_name)
		end		
		
		it "Should not be valid without a first_name" do
			get_first_name			
			@user.first_name = nil
			@user.should_not be_valid		
		end
	end
	
	describe "Last name examples" do
		let(:get_last_name) {
			@user = User.last
			@last_name = @user.last_name
		}
		
		it "Should strip extra trailing spaces" do
			get_last_name			
			@user.last_name = @last_name + '    	    '
			@user.save
			
			@user.last_name.should eq(@last_name)
		end
		
		it "Should strip extra leading spaces" do
			get_last_name			
			@user.last_name = '    	    ' + @last_name 	
			@user.save
			
			@user.last_name.should eq(@last_name)
		end		
		
		it "Should not be valid without a last_name" do
			get_last_name			
			@user.last_name = nil
			@user.should_not be_valid		
		end
	end	
	
	describe "Phone examples" do
		let(:get_phone) {
			@user = User.first
			@phone = @user.phone
		}
		
		it "Should strip extra trailing spaces" do
			get_phone			
			@user.phone = @phone + '    	    '
			@user.save
			
			@user.phone.should eq(@phone)
		end
		
		it "Should strip extra leading spaces" do
			get_phone		
			@user.phone = '    	    ' + @phone
			@user.save
			
			@user.phone.should eq(@phone)
		end		
		
		it "Should not be valid without a phone" do
			get_phone	
			@user.phone = nil
			@user.should_not be_valid		
		end
	end
	
	describe "Email examples" do
		let(:get_email) {
			@user = User.first
			@email = @user.email
		}
		
		it "Should strip extra trailing spaces" do
			get_email			
			@user.email = @email + '    	    '
			@user.save
			
			@user.email.should eq(@email)
		end
		
		it "Should strip extra leading spaces" do
			get_email		
			@user.email = '    	    ' + @email
			@user.save
			
			@user.email.should eq(@email)
		end		
		
		it "Should not be valid without a email" do
			get_email	
			@user.email = nil
			@user.should_not be_valid		
			@user.should have(2).error_on(:email)
		end
		
		it "Should not allow creation of User with existing email" do
			get_email
			user = FactoryGirl.create(:user)
			user.email = @user.email
			
			user.should_not be_valid
			user.should have(2).error_on(:email)
		end
	end		

	describe "Role examples" do
		let(:get_role) {
			@user = User.last
			@role = @user.role
		}
		
		it "Should not be valid without a role" do
			get_role	
			@user.role = nil
			@user.should_not be_valid		
			@user.should have(1).error_on(:role)
		end
		
		it "Should not allow invalid role" do
			get_role
			@user.role = 99
			
			@user.should_not be_valid
			@user.should have(1).error_on(:role)
		end
	end		
	
	# INSTANCE METHOD CHECKS ---------------------------------------------
	describe "Role string method" do
		it "Should return a matching string for Customer" do
			user = User.first
			user.role_str.should match(/Customer/)
		end
		
		it "Should return a matching string for Service Admin" do
			user = User.last
			user.role = User::SERVICE_ADMIN
			user.role_str.should match(/Service Administrator/)		
		end
		
		it "Should return unknown if no matching role" do
			user = User.last
			user.role = 99
			user.role_str.should match(/Unknown/)		
		end
	end
	
	# DEFINED SCOPE TESTS ------------------------------------------------
	describe "Scope tests" do
	
		describe "Search by email" do
			it "Should find all records for broad email search" do
				User.by_email("person").count.should eq(User.count)
			end
			
			it "Should find a single record for full email address" do
				user = User.last
				User.by_email(user.email).first.email.should eq(user.email)
			end
			
			it "Should not find any records, if email does not match" do
				User.by_email("Mickey Mouse").count.should eq(0)
			end
			
			it "Should find all records, if email is empty" do
				User.by_email('').count.should eq(User.count)
			end
		end
	
		describe "Search by first name" do
			it "Should find all records for broad first name search" do
				User.by_first_name("John").count.should eq(User.count)
			end
			
			it "Should find a single record for full first name" do
				user = User.last
				User.by_first_name(user.first_name).first.first_name.should eq(user.first_name)
			end
			
			it "Should not find any records, if first name does not match" do
				User.by_first_name("Mickey Mouse").count.should eq(0)
			end
			
			it "Should find all records, if first_name is empty" do
				User.by_first_name('').count.should eq(User.count)
			end
		end

		describe "Search by last name" do
			it "Should find all records for broad last name search" do
				User.by_last_name("Smith").count.should eq(User.count)
			end
			
			it "Should find a single record for full last name" do
				user = User.first
				User.by_last_name(user.last_name).first.last_name.should eq(user.last_name)
			end
			
			it "Should not find any records, if last name does not match" do
				User.by_first_name("Mickey Mouse").count.should eq(0)
			end

			it "Should find all records, if last_name is empty" do
				User.by_last_name('').count.should eq(User.count)
			end			
		end
		
		describe "Search by role" do
		  it "Should find all customer records" do
		    create_service_admins
		    customers = User.where(role: User::CUSTOMER)
		    user = User.by_role(User::CUSTOMER)
		    user.count.should eq(customers.count)
		  end
		  
		  it "Should find no service admin records, if none exist" do
		    user = User.by_role(User::SERVICE_ADMIN)
		    user.count.should eq(0)
		  end
		  
		  it "Should find no records, if no role specified" do
		    user = User.by_role(nil)
		    user.count.should eq(0)
		  end
		  
		  it "Should find all service admin users" do
		    create_service_admins
		    admins = User.where(role: User::SERVICE_ADMIN)
		    
		    user = User.by_role(User::SERVICE_ADMIN)
		    user.count.should eq(admins.count)
		  end
		  
		  it "Should be able to chain a customer search onto all users" do
		    users = User.all
		    customers = User.where(role: User::CUSTOMER)
		    users = users.by_role(User::CUSTOMER)
		    users.count.should eq(customers.count)
		  end
		  
		  it "Should be able to chain a service admin search onto all users" do
		    users = User.all
		    admins = User.where(role: User::SERVICE_ADMIN)
		    users = users.by_role(User::SERVICE_ADMIN)
		    users.count.should eq(admins.count)
		  end
		  
		  it "Should be able to chain a nil search onto all users" do
		    users = User.all
		    admins = User.where(role: User::SERVICE_ADMIN)
		    users = users.by_role(nil)
		    users.count.should eq(0)
		  end		  
		end
	end
end
