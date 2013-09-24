require 'spec_helper'

describe "subscriptions/show" do
  before(:each) do
    @subscription = assign(:subscription, stub_model(Subscription,
      :plan_id => 1,
      :stripe_id => "Stripe",
      :cancel_at_period_end => "Cancel At Period End",
      :stripe_customer_id => "Stripe Customer",
      :quantity => 2,
      :status => "Status"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Stripe/)
    rendered.should match(/Cancel At Period End/)
    rendered.should match(/Stripe Customer/)
    rendered.should match(/2/)
    rendered.should match(/Status/)
  end
end
