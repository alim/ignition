require 'spec_helper'

describe Subscription do
  include_context 'subscription_setup'
  
  let(:find_a_subscription) {
    @subscription = Subscription.last
  }

  before(:each) { create_subscriptions }
  
  after(:each) { Subscription.destroy_all }

  # METHOD CHECKS ------------------------------------------------------
	describe "Should respond to all accessor methods" do
		it { should respond_to(:stripe_plan_id) }
		it { should respond_to(:cancel_at_period_end) }
		it { should respond_to(:quantity) }
		it { should respond_to(:sub_start) }
		it { should respond_to(:sub_end) }
		it { should respond_to(:status) }
		it { should respond_to(:canceled_at) }
		it { should respond_to(:current_period_start) }
		it { should respond_to(:current_period_end) }
		it { should respond_to(:trial_start) }
		it { should respond_to(:trial_end) }
		it { should respond_to(:user_id) }
	end
  
  # VALIDATION TESTS ---------------------------------------------------
  describe "Validation tests" do
  
    before(:each) {
      find_a_subscription
    }
    
    it "With all fields, model should be valid" do
      sub = FactoryGirl.create(:subscription)
      sub.should be_valid
    end
        
    it "Should not be valid, if stripe_plan_id is missing" do
      @subscription.stripe_plan_id = nil
      @subscription.should_not be_valid
    end    
    
    it "Should not be valid, if quantity is missing" do
      @subscription.quantity = nil
      @subscription.should_not be_valid
    end

    it "Should not be valid, if sub_start is missing" do
      @subscription.sub_start = nil
      @subscription.should_not be_valid
    end    

    it "Should not be valid, if status is missing" do
      @subscription.status = nil
      @subscription.should_not be_valid
    end    
    
    it "Should not be valid, if user_id is missing" do
      @subscription.user_id = nil
      @subscription.should_not be_valid
    end          
  end # VALIDATION TESTS
  
  # STRIPE ACTION TESTS ------------------------------------------------
  describe "Stripe interface tests" do
  
    # Credit card and stripe test data
    let(:cardnum) { "4242424242424242" }
    let(:email) { "johnsmith@example.com" }
    let(:name) { "John Smith" }
    let(:cvcvalue) { "313" }
    let(:token) { @token = get_token(name, cardnum, Date.today.month, 
      (Date.today.year + 1), cvcvalue) }  

      # STRIPE COUPON AND PLAN IDs -------------------------------------------

    let(:coupon_code) { "FREE" }
    let(:bronze_plan_id) { "BRONZE" }
    let(:silver_plan_id) { "SILVER" }
    let(:compare_plan_id) { "NONE" }

      # CREATE STRIPE CUSTOMER FUNCTION ----------------------------------------

    let(:stripe_customer){ 
      @customer = create_customer(@token, email) 
      @user = FactoryGirl.create(:user_with_account)
      @user.account.customer_id = @customer.id

      # Setup for the stripe interactions

        @params = {
                    cardholder_name: name,
                    cardholder_email: email,
                    account: {stripe_cc_token: token.id}
        }

      @user.account.save_with_stripe(@params)
    }
    
    # FIND SUBSCRIPTION AND CREATE CUSTOMER ---------------------------------

    before(:each){
      find_a_subscription
      stripe_customer
    }

    # DELETE ALL USERS AND CUSTOMERS ---------------------------------

    after(:each){
      User.destroy_all
      delete_customer(@customer)
    }
    
  # STRIPE CREATE SUBSCRIPTION TEST ------------------------------------

    describe "Create subscription examples" do
      it "should return subscription object" do
        expect {
          @subscription.subscribe(@user.account,
            silver_plan_id, coupon_code)
#            Subscription::PLAN_OPTIONS[:silver][:plan_id])
        }.to_not raise_error
      end
      
      it "should specify the correct plan for the subscription" do
         @subscription.subscribe(@user.account, silver_plan_id, coupon_code).stripe_plan_id.should eql silver_plan_id
      end
      
    end
    
  # STRIPE UPDATE SUBSCRIPTION TEST ------------------------------------

    describe "Update subscription examples" do
      it "should update the customer's plan" do
       @subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          @subscription.subscribe(@user.account, 
            bronze_plan_id, coupon_code)
#            Subscription::PLAN_OPTIONS[:bronze][:plan_id])
        }.to_not raise_error
      end
      
      it "should specify the correct plan for the subscription" do
         @subscription.subscribe(@user.account, bronze_plan_id, coupon_code).stripe_plan_id.should eql bronze_plan_id
      end      
    end
    
  # STRIPE DELETE SUBSCRIPTION TEST ------------------------------------

    describe "Delete subscription" do
      it "should remove the subscription from the customer's account" do
       @subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          @subscription.cancel_subscription(@user.account)
        }.to_not raise_error
      end
      
      it "should cancel a subscription when the user is deleted" do
       @subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          @subscription.destroy()
        }.to_not raise_error
      end
    end 
   end 
end
