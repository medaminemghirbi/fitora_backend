require "rails_helper"

RSpec.describe "Api::V1::Admin::Organizations", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:basic_plan) { create(:subscription_plan, max_locations: 1) }
  let(:premium_plan) { create(:subscription_plan, max_locations: 3) }

  describe "authorization" do
    it "forbids an owner from accessing the admin organizations list" do
      owner = create(:user, :owner)

      get "/api/v1/admin/organizations", headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids org-scoped staff from accessing the admin organizations list" do
      staff = create(:staff_member)

      get "/api/v1/admin/organizations", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/organizations" do
    it "lists every organization across every owner, not just one" do
      org_a = create(:organization)
      org_b = create(:organization)
      create(:subscription, organization: org_a, subscription_plan: basic_plan)
      create(:subscription, organization: org_b, subscription_plan: premium_plan)

      get "/api/v1/admin/organizations", headers: auth_headers(admin)

      ids = response.parsed_body["organizations"].map { |o| o["id"] }
      expect(ids).to include(org_a.id, org_b.id)
    end
  end

  describe "PATCH /api/v1/admin/organizations/:id/subscription" do
    it "overrides an organization's plan directly, with no payment involved" do
      organization = create(:organization)
      create(:subscription, organization: organization, subscription_plan: basic_plan)

      patch "/api/v1/admin/organizations/#{organization.id}/subscription",
            params: { subscription_plan_id: premium_plan.id },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(organization.reload.subscription.subscription_plan_id).to eq(premium_plan.id)
      expect(Payment.count).to eq(0)
    end

    it "creates a subscription when the organization has none yet" do
      organization = create(:organization)

      patch "/api/v1/admin/organizations/#{organization.id}/subscription",
            params: { subscription_plan_id: premium_plan.id },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(organization.reload.subscription).to be_present
      expect(organization.subscription.subscription_plan_id).to eq(premium_plan.id)
    end
  end

  describe "POST /api/v1/admin/organizations/:id/impersonate" do
    it "issues a real session for the organization's owner, not the admin" do
      organization = create(:organization)

      post "/api/v1/admin/organizations/#{organization.id}/impersonate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["user"]["id"]).to eq(organization.owner.id)
      expect(response.parsed_body["user"]["role"]).to eq("owner")
      expect(response.parsed_body["token"]).to be_present
    end

    it "the issued token actually authenticates as the owner on a normal endpoint" do
      organization = create(:organization)

      post "/api/v1/admin/organizations/#{organization.id}/impersonate", headers: auth_headers(admin)
      token = response.parsed_body["token"]

      get "/api/v1/organization", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["organization"]["id"]).to eq(organization.id)
    end

    it "records who impersonated in the audit log" do
      organization = create(:organization)

      post "/api/v1/admin/organizations/#{organization.id}/impersonate", headers: auth_headers(admin)

      log = AuditLog.order(:created_at).last
      expect(log.action).to eq("admin.impersonation_started")
      expect(log.organization_id).to eq(organization.id)
      expect(log.metadata["admin_id"]).to eq(admin.id)
    end

    it "forbids a non-admin from impersonating" do
      organization = create(:organization)
      owner = create(:user, :owner)

      post "/api/v1/admin/organizations/#{organization.id}/impersonate", headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
