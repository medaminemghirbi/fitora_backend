FactoryBot.define do
  factory :contract_upgrade_request do
    company
    contract_plan
    requested_by { association :user, :owner }
    payment_method { :cash }
  end
end
