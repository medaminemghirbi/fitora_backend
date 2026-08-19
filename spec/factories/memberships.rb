FactoryBot.define do
  factory :membership do
    client
    membership_plan
    company { membership_plan.company }
    status { :active }
    starts_at { 1.day.ago }
    expires_at { 29.days.from_now }
    discount { 0 }
  end
end
