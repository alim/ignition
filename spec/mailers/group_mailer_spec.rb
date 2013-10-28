require "spec_helper"

describe GroupMailer do
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    
    # Collect al deliveries into an array
    ActionMailer::Base.deliveries = []
    
    @group = FactoryGirl.build(:group)
    @user = FactoryGirl.create(:user)
    @group.owner_id = @user.id
    @group.save
    
    @group_email = GroupMailer.member_email(@user, @group).deliver
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
    ActionMailer::Base.deliveries.first.from.should == [Group::GROUP_FROM_EMAIL]
  end
    
end
