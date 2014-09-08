require 'spec_helper'

describe Subscription do
  include_context 'subscription_setup'

  let(:find_a_subscription) {
    @subscription = Subscription.last
  }

  let(:subscription) { Subscription.last }
  let(:bronze_plan_id) { Subscription::PLAN_OPTIONS[:bronze][:plan_id] }
  let(:silver_plan_id) { Subscription::PLAN_OPTIONS[:silver][:plan_id] }
  let(:bronze_plan_name) { Subscription::PLAN_OPTIONS[:bronze][:label] }
  let(:silver_plan_name) { Subscription::PLAN_OPTIONS[:silver][:label] }

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

    it "With all fields, model should be valid" do
      sub = FactoryGirl.create(:subscription)
      sub.should be_valid
    end

    it "Should not be valid, if stripe_plan_id is missing" do
      subscription.stripe_plan_id = nil
      subscription.should_not be_valid
    end

    it "Should not be valid, if quantity is missing" do
      subscription.quantity = nil
      subscription.should_not be_valid
    end

    it "Should not be valid, if sub_start is missing" do
      subscription.sub_start = nil
      subscription.should_not be_valid
    end

    it "Should not be valid, if status is missing" do
      subscription.status = nil
      subscription.should_not be_valid
    end

    it "Should not be valid, if user_id is missing" do
      subscription.user_id = nil
      subscription.should_not be_valid
    end
  end # VALIDATION TESTS

  describe "#plan method tests" do

    it "should return the correct bronze label" do
      subscription.stripe_plan_id = Subscription::PLAN_OPTIONS[:bronze][:plan_id]
      subscription.plan_str.should == Subscription::PLAN_OPTIONS[:bronze][:label]
    end

    it "should return the correct silver label" do
      subscription.stripe_plan_id = Subscription::PLAN_OPTIONS[:silver][:plan_id]
      subscription.plan_str.should == Subscription::PLAN_OPTIONS[:silver][:label]
    end

    it "should return the correct gold label" do
      subscription.stripe_plan_id = Subscription::PLAN_OPTIONS[:gold][:plan_id]
      subscription.plan_str.should == Subscription::PLAN_OPTIONS[:gold][:label]
    end

  end


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

    let(:coupon_code) { "DISCOUNT" }
    let(:coupon_percent_off) { 25 }
    let(:coupon_duration) { "repeating" }
    let(:coupon_duration_months) { 3 }
    let(:compare_plan_id) { "NONE" }
    let(:bronze_plan_amount) { 2500 }
    let(:silver_plan_amount) { 3000 }
    let(:plan_interval) { "month" }
    let(:plan_currency) { "usd" }

    # CREATE STRIPE COUPON ----------------------------------------

    let(:create_stripe_coupon){
      @new_coupon = create_coupon(coupon_code, coupon_percent_off, coupon_duration,coupon_duration_months)
    }

    # DELETE STRIPE COUPON ----------------------------------------

    let(:delete_stripe_coupon){
      @new_coupon = delete_coupon(coupon_code)
    }

    # CREATE STRIPE SUBSCRIPTION PLANS ----------------------------------------

    let(:create_silver_plan){
      @new_plan = create_plan(silver_plan_id, silver_plan_name, silver_plan_amount, plan_interval, plan_currency)
    }

    let(:create_bronze_plan){
      @new_plan = create_plan(bronze_plan_id, bronze_plan_name, bronze_plan_amount, plan_interval, plan_currency)
    }

    # DELETE STRIPE SUBSCRIPTION PLANS ----------------------------------------

    let(:delete_silver_plan){
      @new_plan = delete_plan(silver_plan_id)
    }

    let(:delete_bronze_plan){
      @new_plan = delete_plan(bronze_plan_id)
    }

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
      create_stripe_coupon
      create_silver_plan
      create_bronze_plan
    }

    # DELETE ALL USERS AND CUSTOMERS ---------------------------------

    after(:each){
      User.destroy_all
      delete_customer(@customer)
      delete_stripe_coupon
      delete_silver_plan
      delete_bronze_plan
    }

    # STRIPE CREATE SUBSCRIPTION TEST ------------------------------------

    describe "Create subscription examples", :vcr do
      it "should return subscription object" do
        expect {
          subscription.subscribe(@user.account,
            silver_plan_id, coupon_code)
        }.to_not raise_error
      end

      it "should specify the correct plan for the subscription" do
        subscription.subscribe(@user.account, silver_plan_id, coupon_code).stripe_plan_id.should eql silver_plan_id
      end

    end

  # STRIPE UPDATE SUBSCRIPTION TEST ------------------------------------

    describe "Update subscription examples", :vcr do
      it "should update the customer's plan" do
        subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          subscription.subscribe(@user.account,
            bronze_plan_id, coupon_code)
        }.to_not raise_error
      end

      it "should specify the correct plan for the subscription" do
        subscription.subscribe(@user.account, bronze_plan_id, coupon_code).stripe_plan_id.should eql bronze_plan_id
      end
    end

  # STRIPE DELETE SUBSCRIPTION TEST ------------------------------------

    describe "Delete subscription", :vcr do
      it "should remove the subscription from the customer's account" do
        subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          subscription.cancel_subscription(@user.account)
        }.to_not raise_error
      end

      it "should cancel a subscription when the user is deleted" do
        subscription.subscribe(@user.account, silver_plan_id, coupon_code)
        expect {
          subscription.destroy()
        }.to_not raise_error
      end
    end
   end
end
