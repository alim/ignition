require 'spec_helper'

describe "subscriptions/edit" do
  before(:each) do
    @subscription = assign(:subscription, stub_model(Subscription,
      :plan_id => 1,
      :stripe_id => "MyString",
      :cancel_at_period_end => "MyString",
      :stripe_customer_id => "MyString",
      :quantity => 1,
      :status => "MyString"
    ))
  end

  it "renders the edit subscription form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", subscription_path(@subscription), "post" do
      assert_select "input#subscription_plan_id[name=?]", "subscription[plan_id]"
      assert_select "input#subscription_stripe_id[name=?]", "subscription[stripe_id]"
      assert_select "input#subscription_cancel_at_period_end[name=?]", "subscription[cancel_at_period_end]"
      assert_select "input#subscription_stripe_customer_id[name=?]", "subscription[stripe_customer_id]"
      assert_select "input#subscription_quantity[name=?]", "subscription[quantity]"
      assert_select "input#subscription_status[name=?]", "subscription[status]"
    end
  end
end
