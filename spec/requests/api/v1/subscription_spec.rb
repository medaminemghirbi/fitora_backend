require "rails_helper"

RSpec.describe "Api::V1::Subscription", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:organization) { create(:organization, owner: owner) }

  describe "POST /api/v1/subscription/upgrade-request" do
    let(:plan) { create(:subscription_plan, name: "Premium") }

    it "records the owner's chosen plan and payment method as pending" do
      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: plan.id, payment_method: "card" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")

      request = SubscriptionUpgradeRequest.last
      expect(request.organization).to eq(organization)
      expect(request.subscription_plan).to eq(plan)
      expect(request.requested_by).to eq(owner)
      expect(request.payment_method).to eq("card")
    end

    it "leaves an audit trail" do
      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: plan.id, payment_method: "cash" },
           headers: auth_headers(owner)

      log = AuditLog.last
      expect(log.organization).to eq(organization)
      expect(log.user).to eq(owner)
      expect(log.action).to eq("subscription.upgrade_requested")
    end

    it "rejects an unknown plan" do
      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: -1, payment_method: "cash" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects an inactive plan" do
      inactive_plan = create(:subscription_plan, active: false)

      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: inactive_plan.id, payment_method: "cash" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects an invalid payment method" do
      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: plan.id, payment_method: "crypto" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids staff from requesting an upgrade — only the owner manages billing" do
      manager = create(:staff_member, organization: organization, role: :manager)

      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: plan.id, payment_method: "cash" },
           headers: auth_headers(manager.user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
