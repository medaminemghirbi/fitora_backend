FactoryBot.define do
  factory :contract_plan do
    sequence(:code) { |n| "plan-#{n}" }
    name { "Basic" }
    max_locations { 1 }
    price { 29 }
    billing_period { :monthly }
  end
end
