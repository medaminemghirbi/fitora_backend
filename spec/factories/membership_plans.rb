FactoryBot.define do
  factory :membership_plan do
    organization
    sequence(:name) { |n| "Plan #{n}" }
    price { 89 }
    currency { "TND" }
    duration_days { 30 }
    unlimited_bookings { true }
  end
end
