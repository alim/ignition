# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do 
  factory :active_account, class: Account do
    customer_id { rand(10000..100000).to_s }
    status Account::ACTIVE
  end
end
