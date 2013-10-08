# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :customer_id do |n|
    "#{n}"
  end

  factory :subscription do
    plan_id {rand(1..10000)}
    stripe_id {"#{rand(100000..10000000)}"}
    cancel_at_period_end "MyString"
    stripe_customer_id { generate(:customer_id) }
    quantity {1}
    sub_start { DateTime.now + 1.month }
    sub_end  { DateTime.now + 12.months }
    status "active"
    canceled_at { DateTime.now + 10.months }
    current_period_start { DateTime.now + 1.month }
    current_period_end { DateTime.now + 2.months }
    ended_at { DateTime.now + 10.months }
    trial_start { DateTime.now }
    trial_end { DateTime.now + 1.month }
    user_id {rand(1..100000)}
  end
end
