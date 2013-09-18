require 'spec_helper'

describe User do
  before(:all) {
		5.times.each { FactoryGirl.create(:user) }
	}
	
	after(:all) {
		User.all.each do |user|
			user.destroy
		end
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
end
