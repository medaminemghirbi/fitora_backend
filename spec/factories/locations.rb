FactoryBot.define do
  factory :location do
    organization
    sequence(:name) { |n| "Location #{n}" }
    timezone { "Africa/Tunis" }
  end
end
