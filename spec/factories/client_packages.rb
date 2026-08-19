FactoryBot.define do
  factory :client_package do
    client
    package
    status { :active }
    remaining_credits { 10 }
    purchased_at { 1.day.ago }
    expires_at { 59.days.from_now }
  end
end
