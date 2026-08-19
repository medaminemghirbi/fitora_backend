FactoryBot.define do
  factory :organization do
    association :owner, factory: [ :user, :owner ]
    sequence(:name) { |n| "Studio #{n}" }
    timezone { "Africa/Tunis" }
    currency { "TND" }

    # Every organization has exactly one location in production (auto-created
    # at signup) — mirrored here so specs don't need to remember to create one
    # before exercising anything that reads organization.location.
    after(:create) do |organization|
      create(:location, organization: organization) unless organization.locations.exists?
    end
  end
end
