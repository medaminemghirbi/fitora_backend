FactoryBot.define do
  factory :coach do
    organization
    first_name { "Coach" }
    sequence(:last_name) { |n| "Number#{n}" }
  end
end
