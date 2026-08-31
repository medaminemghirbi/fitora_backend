FactoryBot.define do
  factory :appointment do
    company
    client { association :client, company: company }
    starts_at { 1.day.from_now.change(hour: 10) }
    ends_at { 1.day.from_now.change(hour: 10, min: 30) }
    status { :scheduled }
  end
end
