FactoryBot.define do
  factory :subscription do
    organization
    subscription_plan
    status { :active }
    starts_at { 1.month.ago }
  end
end
