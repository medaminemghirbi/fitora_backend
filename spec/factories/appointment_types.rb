FactoryBot.define do
  factory :appointment_type do
    company
    sequence(:name) { |n| "Consultation #{n}" }
    duration_minutes { 30 }
    color { "#4f46e5" }
    active { true }
  end
end
