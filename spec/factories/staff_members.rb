FactoryBot.define do
  factory :staff_member do
    user { association :user, :staff }
    organization
    role { :manager }
    active { true }
  end
end
