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
		it { should respond_to(:ended_at) }
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
    let(:email) { "janesmith@example.com" }
    let(:name) { "Jane Smith" }
    let(:cvcvalue) { "616" }
    let(:token) { @token = get_token(name, cardnum, Date.today.month, 
      (Date.today.year + 1), cvcvalue) }  
  
    let(:stripe_customer){ 
      @customer = create_customer(@token, email) 
    }
    
    before(:each){
      find_a_subscription
      stripe_customer
      @user = FactoryGirl.create(:user_with_account)
      @user.account.customer_id = @customer.id
    }
  
    after(:each){
      @user.destroy
      delete_customer(@customer)
    }
    
    describe "Create subscription examples" do
      it "should return a Stripe.com subscription object with no options" do
        expect {
          @subscription.subscribe(@account, 
            Subscription::PLAN_OPTIONS[:silver][:plan_id])
        }.to_not raise_error
      end
      
      it "should specify the correct plan for the subscription" do
        pending
      end
      
    end
    
    describe "Update subscription examples" do
      it "should update the customer's plan" do
        expect {
          @subscription.subscribe(@account, 
            Subscription::PLAN_OPTIONS[:bronze][:plan_id])
        }.to_not raise_error
      end
      
      it "should specify the correct plan for the subscription" do
        pending
      end      
    end
    
    describe "Delete subscription" do
      it "should remove the subscription from the customer's account" do
        expect {
          @subscription.cancel_subscription(@account)
        }.to_not raise_error
      end
      
      it "should cancel a subscription when the user is deleted" do
        pending
      end
    end 
  end
end
