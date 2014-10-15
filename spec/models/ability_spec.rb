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

 after(:each) { User.destroy_all }

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
    describe "Subscription Access Tests" do

      # Create a normal user
      let(:normal_user) { FactoryGirl.create(:user) }

      # Create a abnormal user
      let(:abnormal_user) { FactoryGirl.create(:user) }

      # Create a single fake subscription owned by a single user
      let(:subscription_fake_customer) {
        FactoryGirl.create(:subscription, user: normal_user)
      }

      # Create a single fake subscription owned by a single abnormal user
      let(:subscription_fake_abnormal_customer) {
        FactoryGirl.create(:subscription, user: abnormal_user)
      }

      # Subscription Admin Tests with CRUD access rights
      describe "Subscription Admin Access Tests" do

        sub_admin = FactoryGirl.create(:adminuser)
        subject(:admin_ability) { Ability.new(sub_admin) }

        it "Create a Subscription" do
          should be_able_to(:create, subscription_fake_customer)
        end

        it "Read a Subscription" do
          should be_able_to(:read, subscription_fake_customer)
        end

        it "Update a Subscription" do
          should be_able_to(:update, subscription_fake_customer)
        end

        it "Delete a Subscription" do
          should be_able_to(:destroy, subscription_fake_customer)
        end
      end

      # Subscription User Tests with CRUD access rights
      describe "Subscription User Access Tests" do

        subject(:user_ability) { Ability.new(normal_user) }

        it "Create a Subscription" do
          should be_able_to(:create, subscription_fake_customer)
        end

        it "Read a Subscription" do
          should be_able_to(:read, subscription_fake_customer)
        end

        it "Update a Subscription" do
          should be_able_to(:update, subscription_fake_customer)
        end

        it "Delete a Subscription" do
          should be_able_to(:destroy, subscription_fake_customer)
        end
      end

      # Subscription User Tests with Non CRUD access rights
      describe "Subscription Non User Access Tests" do

        it "Create a Subscription" do
          should_not be_able_to(:create, subscription_fake_abnormal_customer)
        end

        it "Read a Subscription" do
          should_not be_able_to(:read, subscription_fake_abnormal_customer)
        end

        it "Update a Subscription" do
          should_not be_able_to(:update, subscription_fake_abnormal_customer)
        end

        it "Delete a Subscription" do
          should_not be_able_to(:destroy, subscription_fake_abnormal_customer)
        end
      end
    end
  end
end
