require "rails_helper"

RSpec.describe "Api::V1::Owner::Reports", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "GET /api/v1/owner/reports/export" do
    context "on a plan with advanced reports (Premium)" do
      let!(:contract) { create(:contract, company: company, contract_plan: create(:contract_plan, code: "premium")) }

      it "returns a styled .xlsx workbook for a monthly period" do
        client = create(:client, company: company)
        create(:payment, company: company, client: client, amount: 100, status: :paid, paid_at: Time.current)

        get "/api/v1/owner/reports/export",
            params: { period_type: "month", period: Date.current.strftime("%Y-%m") },
            headers: auth_headers(owner)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        expect(response.headers["Content-Disposition"]).to include("fitora-rapport-")
        expect(response.body.bytesize).to be > 0
      end

      it "returns a workbook for a yearly period" do
        get "/api/v1/owner/reports/export", params: { period_type: "year", period: Date.current.year.to_s }, headers: auth_headers(owner)

        expect(response).to have_http_status(:ok)
      end

      it "rejects an invalid period" do
        get "/api/v1/owner/reports/export", params: { period_type: "month", period: "not-a-period" }, headers: auth_headers(owner)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "forbids staff — this export is owner-only" do
        manager = create(:staff_member, company: company, role: :manager)

        get "/api/v1/owner/reports/export", params: { period_type: "month", period: "2026-01" }, headers: auth_headers(manager.user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "on Basic, which doesn't include advanced reports" do
      let!(:contract) { create(:contract, company: company, contract_plan: create(:contract_plan, code: "basic")) }

      it "is forbidden with a distinguishable error code" do
        get "/api/v1/owner/reports/export", params: { period_type: "month", period: "2026-01" }, headers: auth_headers(owner)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("plan_feature_locked")
      end
    end
  end
end
