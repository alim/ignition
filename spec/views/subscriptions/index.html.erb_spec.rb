require 'spec_helper'

describe "subscriptions/index" do
  before(:each) do
    assign(:subscriptions, [
      stub_model(Subscription,
        :plan_id => 1,
        :stripe_id => "Stripe",
        :cancel_at_period_end => "Cancel At Period End",
        :stripe_customer_id => "Stripe Customer",
        :quantity => 2,
        :status => "Status"
      ),
      stub_model(Subscription,
        :plan_id => 1,
        :stripe_id => "Stripe",
        :cancel_at_period_end => "Cancel At Period End",
        :stripe_customer_id => "Stripe Customer",
        :quantity => 2,
        :status => "Status"
      )
    ])
  end

  it "renders a list of subscriptions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Stripe".to_s, :count => 2
    assert_select "tr>td", :text => "Cancel At Period End".to_s, :count => 2
    assert_select "tr>td", :text => "Stripe Customer".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
  end
end
