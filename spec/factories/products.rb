FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    price_cents { Faker::Number.between(from: 100, to: 10000) }
    currency { "USD" }
    stock_quantity { Faker::Number.between(from: 0, to: 100) }
    active { true }
    sku { Faker::Alphanumeric.alphanumeric(number: 10).upcase }

    trait :inactive do
      active { false }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :in_stock do
      stock_quantity { Faker::Number.between(from: 1, to: 100) }
    end

    trait :expensive do
      price_cents { Faker::Number.between(from: 50000, to: 100000) }
    end

    trait :cheap do
      price_cents { Faker::Number.between(from: 1, to: 100) }
    end
  end
end
