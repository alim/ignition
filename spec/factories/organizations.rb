# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :organization_name do |n|
    "My Organization - #{n}"
  end

  sequence :organization_desc do |n|
    "My Organization #{n} description"
  end

  # We expect the owner: field to be passed in
  factory :organization do
    name  { generate(:organization_name) }
    description { generate(:organization_desc) }
  end
end
