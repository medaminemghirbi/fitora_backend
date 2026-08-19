FactoryBot.define do
  factory :contract do
    company
    contract_plan
    status { :active }
    starts_at { 1.month.ago }
  end
end
