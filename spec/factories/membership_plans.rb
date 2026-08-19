FactoryBot.define do
  factory :membership_plan do
    company
    sequence(:name) { |n| "Plan #{n}" }
    price { 89 }
    currency { "TND" }
    billing_period { :monthly }
    unlimited_bookings { true }
  end
end
