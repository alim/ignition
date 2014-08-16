require "spec_helper"

describe OrganizationMailer do
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true

    # Collect al deliveries into an array
    ActionMailer::Base.deliveries = []

    @organization = FactoryGirl.build(:organization)
    @user = FactoryGirl.create(:user)
    @organization.owner_id = @user.id
    @organization.save

    @organization_email = OrganizationMailer.member_email(@user, @organization).deliver
  end


  after(:each) do
    ActionMailer::Base.deliveries.clear
    User.destroy_all
  end

  it 'should send an email' do
    ActionMailer::Base.deliveries.count.should == 1
  end

  it 'renders the receiver email' do
    ActionMailer::Base.deliveries.first.to.should == [@user.email]
  end

  it 'renders the sender email' do
    ActionMailer::Base.deliveries.first.from.should == [OrganizationMailer::ORGANIZATION_FROM_EMAIL]
  end

end
