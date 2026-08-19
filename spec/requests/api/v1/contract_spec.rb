require "rails_helper"

RSpec.describe "Api::V1::Contract", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "POST /api/v1/contract/upgrade-request" do
    let(:plan) { create(:contract_plan, name: "Premium") }

    it "records the owner's chosen plan and payment method as pending" do
      post "/api/v1/contract/upgrade-request",
           params: { plan_id: plan.id, payment_method: "card" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")

      request = ContractUpgradeRequest.last
      expect(request.company).to eq(company)
      expect(request.contract_plan).to eq(plan)
      expect(request.requested_by).to eq(owner)
      expect(request.payment_method).to eq("card")
    end

    it "leaves an audit trail" do
      post "/api/v1/contract/upgrade-request",
           params: { plan_id: plan.id, payment_method: "cash" },
           headers: auth_headers(owner)

      log = AuditLog.last
      expect(log.company).to eq(company)
      expect(log.user).to eq(owner)
      expect(log.action).to eq("contract.upgrade_requested")
    end

    it "rejects an unknown plan" do
      post "/api/v1/contract/upgrade-request",
           params: { plan_id: -1, payment_method: "cash" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects an inactive plan" do
      inactive_plan = create(:contract_plan, active: false)

      post "/api/v1/contract/upgrade-request",
           params: { plan_id: inactive_plan.id, payment_method: "cash" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects an invalid payment method" do
      post "/api/v1/contract/upgrade-request",
           params: { plan_id: plan.id, payment_method: "crypto" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids staff from requesting an upgrade — only the owner manages billing" do
      manager = create(:staff_member, company: company, role: :manager)

      post "/api/v1/contract/upgrade-request",
           params: { plan_id: plan.id, payment_method: "cash" },
           headers: auth_headers(manager.user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
