# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription do
    plan_id 1
    stripe_id "MyString"
    cancel_at_period_end "MyString"
    stripe_customer_id "MyString"
    quantity 1
    sub_start "2013-09-17 20:07:39"
    sub_end "2013-09-17 20:07:39"
    status "MyString"
    canceled_at "2013-09-17 20:07:39"
    current_period_start "2013-09-17 20:07:39"
    current_period_end "2013-09-17 20:07:39"
    ended_at "2013-09-17 20:07:39"
    trial_start "2013-09-17 20:07:39"
    trial_end "2013-09-17 20:07:39"
  end
end
