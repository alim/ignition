require 'spec_helper'

describe Subscription do
  include_context 'subscription_setup'
  
  let(:find_a_subscription) {
    @subscription = Subscription.last
  }
  
  before(:each) {
    create_subscriptions
  }

  # METHOD CHECKS ------------------------------------------------------
	describe "Should respond to all accessor methods" do
		it { should respond_to(:plan_id) }
		it { should respond_to(:stripe_id) }
		it { should respond_to(:cancel_at_period_end) }
		it { should respond_to(:stripe_customer_id) }
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
    
    it "Should not be valid, if plan_id is missing" do
      @subscription.plan_id = nil
      @subscription.should_not be_valid
    end
        
    it "Should not be valid, if stripe_id is missing" do
      @subscription.stripe_id = nil
      @subscription.should_not be_valid
    end
    
    it "Should not be valid, if stripe_customer_id is missing" do
      @subscription.stripe_customer_id = nil
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
    
    it "Should not be valid, if sub_end is missing" do
      @subscription.sub_end = nil
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
    describe "Create subscription examples" do
      pending
    end
    
    describe "Update subscription examples" do
      pending
    end
    
    describe "Delete subscription" do
    end 
  end
end
