FactoryBot.define do
  factory :package do
    organization
    sequence(:name) { |n| "Package #{n}" }
    price { 300 }
    currency { "TND" }
    credits { 10 }
    validity_days { 60 }
  end
end
