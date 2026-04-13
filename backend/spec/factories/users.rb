FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { :member }

    trait :librarian do
      role { :librarian }
    end
  end
end
