# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	sequence :email do |n|
    "person#{n}@example.com"
  end

	sequence :firstname do |n|
    "John#{n}"
  end

	sequence :lastname do |n|
    "Smith#{n}"
  end

  factory :user do
    first_name { generate(:firstname) }
    last_name { generate(:lastname) }
    email { generate(:email) }
    phone '734.645.8000'
    role User::CUSTOMER

    password 'somepassword'
    password_confirmation 'somepassword'
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end

	factory :adminuser, class: User do
    first_name { generate(:firstname) }
    last_name { generate(:lastname) }
    email { generate(:email) }
    phone '734.424.1000'
    role User::SERVICE_ADMIN

    password 'somepassword'
    password_confirmation 'somepassword'
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end

  factory :orguser, class: User do
    first_name { generate(:firstname) }
    last_name { generate(:lastname) }
    email { generate(:email) }
    phone '734.424.2000'
    role User::ORG_ADMIN

    password 'somepassword'
    password_confirmation 'somepassword'
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end

  factory :user_with_account, class: User do
    first_name { generate(:firstname) }
    last_name { generate(:lastname) }
    email { generate(:email) }
    phone '734.645.8000'
    role User::CUSTOMER

    password 'somepassword'
    password_confirmation 'somepassword'
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
    account { FactoryGirl.build(:active_account) }
  end

end
