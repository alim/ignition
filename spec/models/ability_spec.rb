require "spec_helper"
require "cancan/matchers"

# TODO: Fill out ability tests
describe Ability do
include_context 'user_setup'
include_context 'subscription_setup'

  let(:customer) { FactoryGirl.create(:user) }
  let(:account_customer) { FactoryGirl.create(:user_with_account) }
  let(:another_customer) { FactoryGirl.create(:user_with_account) }
  let(:admin) { FactoryGirl.create(:adminuser) }

# STRIPE INFORMATION -------------------------------------------

  let(:cardnum) { "4242424242424242" }
  let(:email) { "johnsmith@example.com" }
  let(:name) { "John Smith" }
  let(:cvcvalue) { "313" }
  let(:token) { @token = get_token(name, cardnum, Date.today.month,
      (Date.today.year + 1), cvcvalue) }

  let(:stripe_customer){
      @subscription_customer = create_customer(@token, email)
      @subscription_user = FactoryGirl.create(:user_with_account)
      @subscription_user.account.customer_id = @subscription_customer.id

      # Setup for the stripe interactions

        @params = {
                    cardholder_name: name,
                    cardholder_email: email,
                    account: {stripe_cc_token: token.id}
        }

      @subscription_user.account.save_with_stripe(@params)
    }

     # STRIPE COUPON AND PLAN IDs -------------------------------------------

    let(:coupon_code) { "DISCOUNT" }
    let(:coupon_percent_off) { 25 }
    let(:coupon_duration) { "repeating" }
    let(:coupon_duration_months) { 3 }
    let(:bronze_plan_id) { "BRONZE" }
    let(:silver_plan_id) { "SILVER" }
    let(:compare_plan_id) { "NONE" }
    let(:bronze_plan_amount) { 2500 }
    let(:silver_plan_amount) { 3000 }
    let(:bronze_plan_name) { "Bronze Plan" }
    let(:silver_plan_name) { "Silver Plan" }
    let(:plan_interval) { "month" }
    let(:plan_currency) { "usd" }

  #before (:all) do
      #stripe_customer
  #end

 after(:each) { User.destroy_all }

 describe "Create Subscription Example", :vcr do
   subject(:subscription) { Subscription.new() }

  #before (:all) do
      #stripe_customer
  #end

      it "should return subscription object" do
        expect {
          subscription.subscribe(@subscription_user.account,
            silver_plan_id, coupon_code)
        }.to_not raise_error
      end
 end

  describe "Standard customer user" do
    subject(:ability) { Ability.new(account_customer) }

    describe "Account access" do
      let(:account) { account_customer.account }

      it {should be_able_to(:create, account)}
      it {should be_able_to(:read, account)}
      it {should be_able_to(:update, account)}
      it {should be_able_to(:destroy, account)}

      context "with a different user" do
        let(:account) { another_customer.account }

        it {should_not be_able_to(:create, account)}
        it {should_not be_able_to(:read, account)}
        it {should_not be_able_to(:update, account)}
        it {should_not be_able_to(:destroy, account)}
      end
    end

    describe "Organization access" do
      let(:organization) { FactoryGirl.create(:organization, owner: account_customer) }

      it {should be_able_to(:create, organization)}
      it {should be_able_to(:read, organization)}
      it {should be_able_to(:update, organization)}
      it {should be_able_to(:destroy, organization)}

      context "different owner" do
        let(:organization) { FactoryGirl.create(:organization, owner: another_customer) }

        it {should_not be_able_to(:create, organization)}
        it {should_not be_able_to(:read, organization)}
        it {should_not be_able_to(:update, organization)}
        it {should_not be_able_to(:destroy, organization)}
      end
    end

    describe "Project access" do
      let(:project) { FactoryGirl.create(:project, user: account_customer) }
      let(:org) { FactoryGirl.create(:organization, owner: account_customer ) }

      before(:each) {
        account_customer.organization = org
        project.organization = org
      }

      it {should be_able_to(:read, project)}
      it {should be_able_to(:create, project)}
      it {should be_able_to(:update, project)}
      it {should be_able_to(:destroy, project)}

      context "different owner" do
        let(:project) { FactoryGirl.create(:project, user: another_customer) }
        let(:org) { FactoryGirl.create(:organization, owner: another_customer) }
        before(:each) { account_customer.organization = nil }

        it {should_not be_able_to(:create, project)}
        it {should_not be_able_to(:read, project)}
        it {should_not be_able_to(:update, project)}
        it {should_not be_able_to(:destroy, project)}

      end
    end
  end
end
