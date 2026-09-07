FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    role { "customer" }

    trait :admin do
      role { "admin" }
    end

    trait :with_weak_password do
      password { "short" }
    end
  end
end
