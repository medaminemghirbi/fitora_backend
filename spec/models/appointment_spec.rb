require "rails_helper"

RSpec.describe Appointment do
  let(:company) { create(:company) }

  it "fills title and end time from the type on create" do
    type = create(:appointment_type, company: company, name: "Détartrage", duration_minutes: 20)
    client = create(:client, company: company)
    appt = company.appointments.create!(client: client, appointment_type: type, starts_at: Time.zone.parse("2026-09-01 09:00"))

    expect(appt.title).to eq("Détartrage")
    expect(appt.ends_at).to eq(Time.zone.parse("2026-09-01 09:20"))
  end

  it "rejects an end time before the start" do
    appt = build(:appointment, company: company, starts_at: Time.current, ends_at: 1.hour.ago)
    expect(appt).not_to be_valid
  end

  it "rejects a client from another company" do
    appt = build(:appointment, company: company, client: create(:client))
    expect(appt).not_to be_valid
    expect(appt.errors[:client]).to be_present
  end

  it "in_range catches an appointment that straddles the window edge" do
    client = create(:client, company: company)
    appt = company.appointments.create!(client: client, starts_at: Time.zone.parse("2026-09-01 08:00"), ends_at: Time.zone.parse("2026-09-01 09:00"))
    window = [ Time.zone.parse("2026-09-01 08:30"), Time.zone.parse("2026-09-01 10:00") ]

    expect(company.appointments.in_range(*window)).to include(appt)
  end
end
