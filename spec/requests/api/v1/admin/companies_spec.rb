require "rails_helper"

RSpec.describe "Api::V1::Admin::Companies", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "authorization" do
    it "forbids an owner from accessing the admin companies list" do
      owner = create(:user, :owner)

      get "/api/v1/admin/companies", headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids org-scoped staff from accessing the admin companies list" do
      staff = create(:staff_member)

      get "/api/v1/admin/companies", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/companies" do
    it "lists every company across every owner, not just one" do
      company_a = create(:company)
      company_b = create(:company)
      create(:subscription, company: company_a)
      create(:subscription, company: company_b)

      get "/api/v1/admin/companies", headers: auth_headers(admin)

      ids = response.parsed_body["companies"].map { |o| o["id"] }
      expect(ids).to include(company_a.id, company_b.id)
    end

    it "filters by ?q= on company name, city or owner" do
      match = create(:company, name: "Zen Yoga Monastir", city: "Monastir")
      other = create(:company, name: "Iron Gym Tunis", city: "Tunis")

      get "/api/v1/admin/companies", params: { q: "monastir" }, headers: auth_headers(admin)

      ids = response.parsed_body["companies"].map { |o| o["id"] }
      expect(ids).to include(match.id)
      expect(ids).not_to include(other.id)
      expect(response.parsed_body["meta"]["total"]).to eq(1)
    end
  end

  describe "PATCH /api/v1/admin/companies/:id/subscription" do
    it "overrides a company's access status directly, with no payment involved" do
      company = create(:company)
      create(:subscription, company: company, status: :inactive)

      patch "/api/v1/admin/companies/#{company.id}/subscription",
            params: { status: "active" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(company.reload.subscription.status).to eq("active")
      expect(Payment.count).to eq(0)
    end

    it "creates a subscription when the company has none yet" do
      company = create(:company)

      patch "/api/v1/admin/companies/#{company.id}/subscription",
            params: { status: "active" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(company.reload.subscription).to be_present
      expect(company.subscription.status).to eq("active")
    end
  end

  describe "PATCH /api/v1/admin/companies/:id/mobile_key" do
    it "sets the mobile pairing key to a specific admin-chosen value" do
      company = create(:company)

      patch "/api/v1/admin/companies/#{company.id}/mobile_key", params: { mobile_auth_key: "powergym1" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(company.reload.mobile_auth_key).to eq("powergym1")
    end

    it "rejects an uppercase or symbol-containing key" do
      company = create(:company)

      patch "/api/v1/admin/companies/#{company.id}/mobile_key", params: { mobile_auth_key: "Power-Gym!" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a key already used by another company" do
      create(:company, mobile_auth_key: "takenkey")
      company = create(:company)

      patch "/api/v1/admin/companies/#{company.id}/mobile_key", params: { mobile_auth_key: "takenkey" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids a non-admin from setting the key" do
      company = create(:company)
      owner = create(:user, :owner)

      patch "/api/v1/admin/companies/#{company.id}/mobile_key", params: { mobile_auth_key: "powergym1" }, headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/admin/companies/:id/impersonate" do
    it "issues a real session for the company's owner, not the admin" do
      company = create(:company)

      post "/api/v1/admin/companies/#{company.id}/impersonate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["user"]["id"]).to eq(company.owner.id)
      expect(response.parsed_body["user"]["role"]).to eq("owner")
      expect(response.parsed_body["token"]).to be_present
    end

    it "the issued token actually authenticates as the owner on a normal endpoint" do
      company = create(:company)

      post "/api/v1/admin/companies/#{company.id}/impersonate", headers: auth_headers(admin)
      token = response.parsed_body["token"]

      get "/api/v1/company", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["id"]).to eq(company.id)
    end

    it "records who impersonated in the audit log" do
      company = create(:company)

      post "/api/v1/admin/companies/#{company.id}/impersonate", headers: auth_headers(admin)

      log = AuditLog.order(:created_at).last
      expect(log.action).to eq("admin.impersonation_started")
      expect(log.company_id).to eq(company.id)
      expect(log.metadata["admin_id"]).to eq(admin.id)
    end

    it "forbids a non-admin from impersonating" do
      company = create(:company)
      owner = create(:user, :owner)

      post "/api/v1/admin/companies/#{company.id}/impersonate", headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
