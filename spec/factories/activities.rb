FactoryBot.define do
  factory :activity do
    location
    sequence(:name) { |n| "Activity #{n}" }
    activity_type { :group_class }
    duration { 60 }
    capacity { 10 }
  end
end
