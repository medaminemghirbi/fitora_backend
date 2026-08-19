require "rails_helper"

RSpec.describe "Api::V1::Admin::Companies", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:basic_plan) { create(:contract_plan, max_locations: 1) }
  let(:premium_plan) { create(:contract_plan, max_locations: 3) }

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
      org_a = create(:company)
      org_b = create(:company)
      create(:contract, company: org_a, contract_plan: basic_plan)
      create(:contract, company: org_b, contract_plan: premium_plan)

      get "/api/v1/admin/companies", headers: auth_headers(admin)

      ids = response.parsed_body["companies"].map { |o| o["id"] }
      expect(ids).to include(org_a.id, org_b.id)
    end
  end

  describe "PATCH /api/v1/admin/companies/:id/contract" do
    it "overrides an company's plan directly, with no payment involved" do
      company = create(:company)
      create(:contract, company: company, contract_plan: basic_plan)

      patch "/api/v1/admin/companies/#{company.id}/contract",
            params: { contract_plan_id: premium_plan.id },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(company.reload.contract.contract_plan_id).to eq(premium_plan.id)
      expect(Payment.count).to eq(0)
    end

    it "creates a contract when the company has none yet" do
      company = create(:company)

      patch "/api/v1/admin/companies/#{company.id}/contract",
            params: { contract_plan_id: premium_plan.id },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(company.reload.contract).to be_present
      expect(company.contract.contract_plan_id).to eq(premium_plan.id)
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
