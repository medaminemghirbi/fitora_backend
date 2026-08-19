require "rails_helper"

RSpec.describe "Api::V1::Memberships", type: :request do
  let(:owner) { create(:user, :owner) }
  let(:company) { create(:company, owner: owner) }

  describe "company isolation" do
    it "never exposes another company's memberships to an owner" do
      create(:contract, company: company, contract_plan: create(:contract_plan))

      other_org = create(:company)
      other_plan = create(:membership_plan, company: other_org)
      create(:membership, membership_plan: other_plan)

      get "/api/v1/memberships", headers: auth_headers(owner)

      expect(response.parsed_body["memberships"]).to eq([])
    end
  end

  describe "POST /api/v1/memberships" do
    it "lets the owner give a client a membership, active immediately" do
      plan = create(:membership_plan, company: company, active: true, price: 89)
      client = create(:client, company: company)

      post "/api/v1/memberships",
           params: { client_id: client.id, membership_plan_id: plan.id, payment_method: "cash", payment_amount: "89" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["membership"]["status"]).to eq("active")
      expect(response.parsed_body["membership"]["payment_status"]).to eq("paid")
      expect(response.parsed_body["payment"]["status"]).to eq("paid")
    end

    it "creates the membership unpaid when no payment is recorded" do
      plan = create(:membership_plan, company: company, active: true)
      client = create(:client, company: company)

      post "/api/v1/memberships", params: { client_id: client.id, membership_plan_id: plan.id }, headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["membership"]["payment_status"]).to eq("unpaid")
      expect(response.parsed_body["payment"]).to be_nil
    end

    it "forbids a coach from giving a client a membership" do
      plan = create(:membership_plan, company: company, active: true)
      client = create(:client, company: company)
      coach = create(:staff_member, company: company, role: :coach)

      post "/api/v1/memberships", params: { client_id: client.id, membership_plan_id: plan.id }, headers: auth_headers(coach.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/memberships/:id/renew" do
    it "creates a new membership starting when the current one ends, without touching history" do
      plan = create(:membership_plan, company: company)
      client = create(:client, company: company)
      original = create(:membership, client: client, membership_plan: plan, company: company,
                                      starts_at: 30.days.ago, expires_at: 1.day.from_now)

      post "/api/v1/memberships/#{original.id}/renew", headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      new_membership = response.parsed_body["membership"]
      expect(new_membership["id"]).not_to eq(original.id)
      expect(client.memberships.count).to eq(2)
      expect(original.reload.status).to eq("active") # history untouched
    end
  end

  describe "GET /api/v1/memberships/:id/receipt" do
    let(:plan) { create(:membership_plan, company: company, price: 89) }
    let(:client) { create(:client, company: company) }
    let(:membership) { create(:membership, client: client, membership_plan: plan, company: company) }

    context "on a plan with advanced reports (Premium)" do
      before { create(:contract, company: company, contract_plan: create(:contract_plan, code: "premium")) }

      it "returns a PDF" do
        create(:payment, company: company, client: client, membership: membership, amount: 89, status: :paid)

        get "/api/v1/memberships/#{membership.id}/receipt", headers: auth_headers(owner)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("recu-")
        expect(response.body.byteslice(0, 4)).to eq("%PDF")
      end

      it "still returns a PDF when nothing has been paid yet" do
        get "/api/v1/memberships/#{membership.id}/receipt", headers: auth_headers(owner)

        expect(response).to have_http_status(:ok)
        expect(response.body.byteslice(0, 4)).to eq("%PDF")
      end

      it "is available to staff who can see memberships, not just the owner" do
        receptionist = create(:staff_member, company: company, role: :receptionist)

        get "/api/v1/memberships/#{membership.id}/receipt", headers: auth_headers(receptionist.user)

        expect(response).to have_http_status(:ok)
      end

      it "forbids a coach, who has no memberships capability" do
        coach = create(:staff_member, company: company, role: :coach)

        get "/api/v1/memberships/#{membership.id}/receipt", headers: auth_headers(coach.user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "on Basic, which doesn't include advanced reports" do
      before { create(:contract, company: company, contract_plan: create(:contract_plan, code: "basic")) }

      it "is forbidden with a distinguishable error code" do
        get "/api/v1/memberships/#{membership.id}/receipt", headers: auth_headers(owner)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("plan_feature_locked")
      end
    end
  end
end
