FactoryBot.define do
  factory :membership do
    client
    membership_plan
    organization { membership_plan.organization }
    status { :active }
    starts_at { 1.day.ago }
    expires_at { 29.days.from_now }
    discount { 0 }
  end
end
