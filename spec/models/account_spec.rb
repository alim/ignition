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

    let(:user) { User.first }

    describe "Saving with stripe attributes" do

    	context "Valid attributes", :vcr do

		    let(:token) do
		    	@token = get_token(name, cardnum, Date.today.month, (Date.today.year + 1),
		    		cvcvalue)
		  	end

		    let(:params) do
		    	{
						cardholder_name: name,
						cardholder_email: email,
						account: {stripe_cc_token: @token.id}
		    	}
		    end

		    before { token }

	      it "Should allow saving with stripe information to account record" do
				  user.account.save_with_stripe(params).should be_true
			  end

			  it "Should update account with stripe customer id" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.customer_id.should be_present
			  end

			  it "Should update account with stripe customer email" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.cardholder_email.should eq(params[:cardholder_email])
			  end

			  it "Should update account with stripe customer name" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.cardholder_name.should eq(params[:cardholder_name])
			  end

			  it "Should update account with last4 of credit card" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.last4.should eq(cardnum.split(//).last(4).join)
			  end

			  it "Should set account with credit card_type" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.card_type.should eq("Visa")
			  end

			  it "Should set account with credit card expiration date" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.expiration.should eq(@token.card[:exp_month].to_s + '/' +
			      @token.card[:exp_year].to_s)
			  end

			  it "Should update account status to ACTIVE" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.status.should eq(Account::ACTIVE)
			  end
			end

			context 'Invalid stripe attributes', :vcr do

		    let(:token) do
	    		@token = get_token(name, cardnum, Date.today.month, (Date.today.year + 1),
	    			cvcvalue)
		    end

		    let(:params) do
		    	{
						cardholder_name: name,
						cardholder_email: email,
						account: {stripe_cc_token: @token.id}
		    	}
		    end

		    before { token }

			  it "Should not save the account with an invalid token" do
			    params[:account][:stripe_cc_token] = '123451234512345'
			    user.account.save_with_stripe(params).should be_false

			    user.account.status.should eq(Account::INACTIVE)
				  user.account.errors.full_messages[0].should match(/Customer Invalid token id: 123451234512345/)
				end
			end
		end

		describe "Updating with stripe attributes" do
	    let(:new_email) { "janedoe@example.com" }
	    let(:new_name) { "Jane Doe" }

			context "Valid stripe account update tests", :vcr do

		    let(:first_token) do
		    	@first_token = get_token(name, cardnum, Date.today.month, (Date.today.year + 1),
		    		cvcvalue)
				end

		    let(:second_token) do
		    	@second_token = get_token(new_name, cardnum, Date.today.month, (Date.today.year + 2),
		    		cvcvalue)
				end

		  	let(:params) do
			  	{
					  cardholder_name: name,
					  cardholder_email: email,
					  account: {stripe_cc_token: @first_token.id}
					}
			  end

			  let(:update_params) do
			  	{
					  cardholder_name: new_name,
					  cardholder_email: new_email,
					  account: {stripe_cc_token: @second_token.id}
					}
			  end

			  before do
			  	first_token
			  	second_token
			  end

			  it "Should update a saved account with new attributes" do
			    user.account.save_with_stripe(params).should be_true
			    customer_id = user.account.customer_id

			    # Update record and check attributes
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.customer_id.should eq(customer_id)
			  end


			  it "Should update account with stripe customer email" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.cardholder_email.should eq(update_params[:cardholder_email])
			  end

			  it "Should update account with stripe customer name" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.cardholder_name.should eq(update_params[:cardholder_name])
			  end

			  it "Should update account with last4 of credit card" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.last4.should eq(cardnum.split(//).last(4).join)
			  end

			  it "Should set account with credit card_type" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.card_type.should eq("Visa")
			  end

			  it "Should set account with credit card expiration date" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.expiration.should eq(@second_token.card[:exp_month].to_s + '/' +
			      @second_token.card[:exp_year].to_s)
			  end

			  it "Should update a saved account and status should be ACTIVE" do
			    user.account.save_with_stripe(params).should be_true

			    # Update record and check attributes
			    user.account.update_with_stripe(update_params).should be_true
			    user.account.status.should eq(Account::ACTIVE)
			  end
			end

			context "Updating with invalid stripe attributes", :vcr do

		    let(:third_token) do
		    	@third_token = get_token(name, cardnum, Date.today.month, (Date.today.year + 1),
		    		cvcvalue)
				end

		    let(:forth_token) do
		    	@forth_token = get_token(new_name, cardnum, Date.today.month, (Date.today.year + 2),
		    		cvcvalue)
				end

		  	let(:params) do
			  	{
					  cardholder_name: name,
					  cardholder_email: email,
					  account: {stripe_cc_token: third_token.id}
					}
			  end

			  let(:update_params) do
			  	{
					  cardholder_name: new_name,
					  cardholder_email: new_email,
					  account: {stripe_cc_token: forth_token.id}
					}
			  end

			  it "Should not update the account with an invalid token" do
			    user.account.save_with_stripe(params).should be_true
			    update_params[:account][:stripe_cc_token] = '123412341234'

			    # Update record and check attributes
			    user.account.update_with_stripe(update_params).should be_false
			    user.account.status.should eq(Account::INACTIVE)
			  end
			end

		end

		describe "Get customer method" do

			context "Valid customer get operation tests", :vcr do

				let(:name) { 'Mickey Mouse' }

				let(:info_token) do
		    	@info_token = get_token(name, cardnum, Date.today.month, (Date.today.year + 3),
		    		cvcvalue)
				end

		  	let(:params) do
			  	{
					  cardholder_name: name,
					  cardholder_email: email,
					  account: {stripe_cc_token: @info_token.id}
					}
			  end

			  before { info_token }

			  it "Should retrieve the correct email address" do
				  user.account.save_with_stripe(params).should be_true
				  user.account.get_customer
				  user.account.cardholder_email.should eq(email)
			  end

			  it "Should retrieve the correct cardholder name" do
				  user.account.save_with_stripe(params).should be_true
				  user.account.get_customer
				  user.account.cardholder_name.should eq(name)
			  end

			  it "Should retrieve the correct cardholder last 4 digits" do
				  user.account.save_with_stripe(params).should be_true
				  user.account.get_customer
				  user.account.last4.should eq(cardnum.split(//).last(4).join)
			  end

			  it "Should retrieve the correct card expiration" do
				  user.account.save_with_stripe(params).should be_true
				  user.account.get_customer

				  month = @info_token.card[:exp_month].to_s
				  year = @info_token.card[:exp_year].to_s
				  user.account.expiration.should match(/#{month}\/#{year}/)
			  end

	      it "Should have a status of ACTIVE" do
				  user.account.save_with_stripe(params).should be_true
				  user.account.get_customer
				  user.account.status.should eq(Account::ACTIVE)
			  end
			end

			context 'Invalid get customer data tests', :vcr do

				let(:name) { 'Mickey Mouse' }

				let(:info_token) do
	    		get_token(name, cardnum, Date.today.month, (Date.today.year + 3),
	    			cvcvalue)
				end

		  	let(:params) do
			  	{
					  cardholder_name: name,
					  cardholder_email: email,
					  account: {stripe_cc_token: info_token.id}
					}
			  end

			  it "Should return an error, if customer_id is invalid" do
			    user.account.save_with_stripe(params).should be_true
			    user.account.customer_id = '1234123412341234'
			    user.account.get_customer.should be_nil
					user.account.errors.full_messages[0].should match(/Customer No such customer:/)
			  end
			end
		end
	end # Stripe interactions
end
