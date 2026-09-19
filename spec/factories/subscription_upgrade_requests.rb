FactoryBot.define do
  factory :subscription_upgrade_request do
    organization
    subscription_plan
    requested_by { association :user, :owner }
    payment_method { :cash }
  end
end
