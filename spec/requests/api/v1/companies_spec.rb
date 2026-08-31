require "rails_helper"

RSpec.describe "Api::V1::Companies", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "GET /api/v1/company" do
    it "returns the owner's company" do
      get "/api/v1/company", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["id"]).to eq(company.id)
    end

    it "forbids staff from reading company settings" do
      staff = create(:staff_member, company: company, role: :manager)

      get "/api/v1/company", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/company — navigation labels" do
    it "stores string overrides and drops blank ones" do
      patch "/api/v1/company",
            params: { company: { nav_labels: { "nav.clients" => "Patients", "nav.contracts" => "  ", "nav.calendar" => "Rendez-vous" } } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(company.reload.nav_labels).to eq("nav.clients" => "Patients", "nav.calendar" => "Rendez-vous")
    end
  end

  describe "PATCH /api/v1/company — branding" do
    it "sets a slug and a primary color" do
      patch "/api/v1/company", params: { company: { slug: "power-gym", primary_color: "#ff5500" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["company"]
      expect(body["slug"]).to eq("power-gym")
      expect(body["primary_color"]).to eq("#ff5500")
    end

    it "uploads a logo" do
      patch "/api/v1/company", params: { company: { logo: fixture_file_upload("sample.png", "image/png") } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["logo_url"]).to be_present
    end

    it "rejects an invalid hex color" do
      patch "/api/v1/company", params: { company: { primary_color: "orange" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a slug with uppercase or spaces" do
      patch "/api/v1/company", params: { company: { slug: "Power Gym" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a slug already used by another company" do
      create(:company, slug: "power-gym")

      patch "/api/v1/company", params: { company: { slug: "power-gym" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "defaults working_days to Monday–Friday" do
      get "/api/v1/company", headers: auth_headers(owner)

      expect(response.parsed_body["company"]["working_days"]).to eq([ 1, 2, 3, 4, 5 ])
    end

    it "updates working_days (a Saturday-opening gym)" do
      patch "/api/v1/company", params: { company: { working_days: [ 6, 1, 2, 3, 4 ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["working_days"]).to eq([ 1, 2, 3, 4, 6 ])
      expect(company.reload.working_days).to eq([ 1, 2, 3, 4, 6 ])
    end

    it "rejects an empty working_days list" do
      patch "/api/v1/company", params: { company: { working_days: [ "" ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an out-of-range weekday" do
      patch "/api/v1/company", params: { company: { working_days: [ 1, 2, 7 ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids staff from changing branding" do
      staff = create(:staff_member, company: company, role: :manager)

      patch "/api/v1/company", params: { company: { primary_color: "#ff5500" } }, headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
      expect(company.reload.primary_color).to be_nil
    end
  end
end
