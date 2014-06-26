require "spec_helper"
require "cancan/matchers"

# TODO: Fill out ability tests
describe Ability do
  let(:customer) { FactoryGirl.create(:user) }
  let(:account_customer) { FactoryGirl.create(:user_with_account) }
  let(:another_customer) { FactoryGirl.create(:user_with_account) }
  let(:org) { FactoryGirl.create(:orgusers) }
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

      it {should be_able_to(:read, seqtype)}
      it {should_not be_able_to(:create, seqtype)}
      it {should_not be_able_to(:update, seqtype)}
      it {should_not be_able_to(:destroy, seqtype)}
    end
  end
end
