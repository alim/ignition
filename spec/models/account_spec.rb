require 'spec_helper'

describe Account do
  include_context 'user_setup'

  before(:each) {
    create_users_with_account
  }
  
  after(:each) {
    User.destroy_all
  }
  
  # METHOD CHECKS ------------------------------------------------------
	describe "Method check" do
		it { should respond_to(:status) }
		it { should respond_to(:customer_id)}
		it { should respond_to(:status_str) }
		it { should respond_to(:stripe_cc_token) }
		it { should respond_to(:cardholder_email) }
		it { should respond_to(:cardholder_name)}
		it { should respond_to(:last4) }
		it { should respond_to(:card_type) }
		it { should respond_to(:expiration) }
	end
	
	# STATUS STRING CHECKS -----------------------------------------------
	describe "Status string checks" do
	  before(:each){
	    @account = User.first.account
	  }
	
	  it "Should return Unknown string for UNKNOWN status" do
	    @account.status = Account::UNKNOWN
	    @account.status_str.should eq("Unknown")
	  end
	
	  it "Should return Active string for ACTIVE status" do
	    @account.status = Account::ACTIVE
	    @account.status_str.should eq("Active")
	  end

	  it "Should return InActive string for INACTIVE status" do
	    @account.status = Account::INACTIVE
	    @account.status_str.should eq("Inactive")
	  end

	  it "Should return Closed string for CLOSED status" do
	    @account.status = Account::CLOSED
	    @account.status_str.should eq("Closed")
	  end	  	  

	  it "Should return No Stripe Account string for NO_STRIPE status" do
	    @account.status = Account::NO_STRIPE
	    @account.status_str.should eq("No Stripe Account")
	  end
	end
	
	# STRIPE.COM INTERACTIONS --------------------------------------------
	describe "Stripe Interactions" do
    let(:cardnum) { "4242424242424242" }
    let(:email) { "andylim@example.com" }
    let(:name) { "Andy Lim" }
    let(:cvcvalue) { "313" }
    let(:token) { get_token(name, cardnum, Date.today.month, 
      (Date.today.year + 1), cvcvalue) }

	  before(:each) do
			# Setup for the stripe interactions
			@params = {
				cardholder_name: name,
				cardholder_email: email,
				account: {stripe_cc_token: token.id}
			}
      
      @user = User.first
  	end
    
    describe "Saving with stripe attributes" do
      it "Should allow saving with stripe information to account record" do
			  @user.account.save_with_stripe(@params, @user).should be_true
		  end
		  
		  it "Should update account with stripe customer id" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.customer_id.should be_present
		  end
		  
		  it "Should update account with stripe customer email" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.cardholder_email.should eq(@params[:cardholder_email])
		  end

		  it "Should update account with stripe customer name" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.cardholder_name.should eq(@params[:cardholder_name])
		  end
		  
		  it "Should update account with last4 of credit card" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.last4.should eq(cardnum.split(//).last(4).join)
		  end		  
		  
		  it "Should set account with credit card_type" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.card_type.should eq("Visa")
		  end			  

		  it "Should set account with credit card expiration date" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.expiration.should eq(Date.today.month.to_s + '/' +
		      (Date.today.year + 1).to_s)
		  end	
		  
		  it "Should update account status to ACTIVE" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.status.should eq(Account::ACTIVE)
		  end		
		  
		  it "Should not save the account with an invalid token" do
		    @params[:account][:stripe_cc_token] = '123451234512345'
		    @user.account.save_with_stripe(@params, @user).should be_false
		    
		    @user.account.status.should eq(Account::INACTIVE)
			  @user.account.errors.full_messages[0].should match(/Customer Invalid token id: 123451234512345/)
		  end  
		end # Saving with stripe attributes
		
		describe "Updating with stripe attributes" do
      
      let(:new_email) { "janedoe@example.com" }
      let(:new_name) { "Jane Doe" }

      let(:new_token) { get_token(new_name, cardnum, Date.today.month, 
        (Date.today.year + 1), cvcvalue) }

	    before(:each) do
			  # Setup for the stripe interactions
			  @new_params = {
				  cardholder_name: new_name,
				  cardholder_email: new_email,
				  account: {stripe_cc_token: new_token.id}
			  }
			end	
			
		  it "Should update a saved account with new attributes" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    customer_id = @user.account.customer_id
		    
		    # Update record and check attributes
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.customer_id.should eq(customer_id)
		  end

		  
		  it "Should update account with stripe customer email" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.cardholder_email.should eq(@new_params[:cardholder_email])
		  end

		  it "Should update account with stripe customer name" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.cardholder_name.should eq(@new_params[:cardholder_name])
		  end
		  
		  it "Should update account with last4 of credit card" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.last4.should eq(cardnum.split(//).last(4).join)
		  end		  
		  
		  it "Should set account with credit card_type" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.card_type.should eq("Visa")
		  end			  

		  it "Should set account with credit card expiration date" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.update_with_stripe(@new_params, @user).should be_true		    
		    @user.account.expiration.should eq(Date.today.month.to_s + '/' +
		      (Date.today.year + 1).to_s)
		  end	
		  
		  it "Should update a saved account and status should be ACTIVE" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    
		    # Update record and check attributes
		    @user.account.update_with_stripe(@new_params, @user).should be_true
		    @user.account.status.should eq(Account::ACTIVE)
		  end
		  
		  it "Should not update the account with an invalid token" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @new_params[:account][:stripe_cc_token] = '123412341234'
		    
		    # Update record and check attributes
		    @user.account.update_with_stripe(@new_params, @user).should be_false
		    @user.account.status.should eq(Account::INACTIVE)
		  end
		end # Updating with stripe attributes
		
		describe "Get customer method" do
		   it "Should retrieve the correct email address" do
			  @user.account.save_with_stripe(@params, @user).should be_true
			  @user.account.get_customer
			  @user.account.cardholder_email.should eq(email)
		  end

		   it "Should retrieve the correct cardholder name" do
			  @user.account.save_with_stripe(@params, @user).should be_true
			  @user.account.get_customer
			  @user.account.cardholder_name.should eq(name)
		  end
		  
		  it "Should retrieve the correct cardholder last 4 digits" do
			  @user.account.save_with_stripe(@params, @user).should be_true
			  @user.account.get_customer
			  @user.account.last4.should eq(cardnum.split(//).last(4).join)
		  end
		  
		  it "Should retrieve the correct card expiration" do
			  @user.account.save_with_stripe(@params, @user).should be_true
			  @user.account.get_customer

			  month = Date.today.month.to_s
			  year = (Date.today.year + 1).to_s
			  @user.account.expiration.should match(/#{month}\/#{year}/)
		  end
		  
      it "Should have a status of ACTIVE" do
			  @user.account.save_with_stripe(@params, @user).should be_true
			  @user.account.get_customer
			  @user.account.status.should eq(Account::ACTIVE)
		  end
		    
		  it "Should return an error, if customer_id is invalid" do
		    @user.account.save_with_stripe(@params, @user).should be_true
		    @user.account.customer_id = '1234123412341234'
		    @user.account.get_customer.should be_nil
				@user.account.errors.full_messages[0].should match(/Customer No such customer:/)	    
		  end
		  
		end # Get customer method
		
	end # Stripe interactions
end
