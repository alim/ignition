require "spec_helper"

describe ContactMailer do
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    
    # Collect al deliveries into an array
    ActionMailer::Base.deliveries = []
    
    @contact = FactoryGirl.build(:contact)
    @contact_email = ContactMailer.contact_message(@contact).deliver
  end
  
  
  after(:each) do
    ActionMailer::Base.deliveries.clear
  end
  
  it 'should send an email' do
    ActionMailer::Base.deliveries.count.should == 1
  end
  
  it 'renders the receiver email' do
    ActionMailer::Base.deliveries.first.to.should == [@contact.email]
  end
  
  it 'renders the sender email' do  
    ActionMailer::Base.deliveries.first.from.should == [Contact::CONTACT_FROM]
  end
    
end
