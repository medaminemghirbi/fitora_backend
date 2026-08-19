FactoryBot.define do
  factory :staff_member do
    user { association :user, :staff }
    company
    role { :manager }
    active { true }
  end
end
