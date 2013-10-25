# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence :project_name do |n|
    "My Project - #{n}"
  end

  sequence :project_desc do |n|
    "My Project #{n} description"
  end

  # Expects a user to be passed in
  factory :project do
    name  { generate(:project_name) }
    description { generate(:project_desc) }
  end
  
end
