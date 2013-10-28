# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do 
  sequence :contact_name do |n| 
    "Mickey Mouse#{n}" 
  end
  
  sequence :contact_body do |n| 
    "Message body - #{n}\nThis is a sample contact message for testing." 
  end
  
  factory :contact, class: Contact do
    name { generate(:contact_name) }
    email Contact::CONTACT_EMAILBOX
    phone "734.555.1212"
    body { generate(:contact_body) }
  end
end
