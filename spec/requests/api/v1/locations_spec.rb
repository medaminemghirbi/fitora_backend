require "rails_helper"

RSpec.describe "Api::V1::Location", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "GET /api/v1/location" do
    it "returns the company's own location, never another company's" do
      other_org = create(:company)

      get "/api/v1/location", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["location"]["id"]).to eq(company.location.id)
      expect(response.parsed_body["location"]["id"]).not_to eq(other_org.location.id)
    end

    it "forbids staff without the locations capability (e.g. a coach)" do
      coach_staff = create(:staff_member, company: company, role: :coach)

      get "/api/v1/location", headers: auth_headers(coach_staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/location" do
    it "updates the company's location" do
      patch "/api/v1/location", params: { location: { name: "New Name", business_hours_start: "07:00", business_hours_end: "21:00" } },
                                 headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(company.location.reload.name).to eq("New Name")
    end

    it "lets a manager (locations capability) update it too" do
      manager = create(:staff_member, company: company, role: :manager)

      patch "/api/v1/location", params: { location: { name: "Updated by manager" } }, headers: auth_headers(manager.user)

      expect(response).to have_http_status(:ok)
      expect(company.location.reload.name).to eq("Updated by manager")
    end
  end
end
