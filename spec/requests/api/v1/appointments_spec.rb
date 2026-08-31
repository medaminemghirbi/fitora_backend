require "rails_helper"

RSpec.describe "Api::V1::Appointments", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }
  let(:client) { create(:client, company: company) }

  def enable_appointments
    company.company_modules.find_or_create_by!(key: "appointments") { |m| m.enabled = true }
  end

  it "403s when the appointments module is off" do
    get "/api/v1/appointments", headers: auth_headers(owner)
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body["error"]).to eq("module_not_enabled")
  end

  context "with the module enabled" do
    before { enable_appointments }

    it "creates an appointment, deriving the end time from the type" do
      type = create(:appointment_type, company: company, duration_minutes: 45)

      post "/api/v1/appointments",
           params: { appointment: { client_id: client.id, appointment_type_id: type.id, starts_at: "2026-09-02T09:00:00Z" } },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      body = response.parsed_body["appointment"]
      expect(body["client_name"]).to eq(client.full_name)
      expect(Time.zone.parse(body["ends_at"])).to eq(Time.zone.parse("2026-09-02T09:45:00Z"))
    end

    it "filters by date range" do
      create(:appointment, company: company, client: client, starts_at: Time.zone.parse("2026-09-02 09:00"), ends_at: Time.zone.parse("2026-09-02 09:30"))
      create(:appointment, company: company, client: client, starts_at: Time.zone.parse("2026-09-20 09:00"), ends_at: Time.zone.parse("2026-09-20 09:30"))

      get "/api/v1/appointments", params: { from: "2026-09-01T00:00:00Z", to: "2026-09-05T00:00:00Z" }, headers: auth_headers(owner)

      expect(response.parsed_body["appointments"].size).to eq(1)
    end

    it "cancels an appointment" do
      appt = create(:appointment, company: company, client: client)

      post "/api/v1/appointments/#{appt.id}/cancel", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(appt.reload).to be_cancelled
    end

    it "won't touch another company's appointment" do
      other = create(:appointment)
      get "/api/v1/appointments/#{other.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)
    end
  end
end
