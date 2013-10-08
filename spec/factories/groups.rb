# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :group_name do |n|
    "My Group - #{n}"
  end

  sequence :group_desc do |n|
    "My Group #{n} description"
  end

  factory :group do
    name  { generate(:group_name) }
    description { generate(:group_desc) }
    owner_id { rand(1..10000) }
  end
end
