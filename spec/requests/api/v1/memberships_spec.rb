require "rails_helper"

RSpec.describe "Api::V1::Memberships", type: :request do
  let(:owner) { create(:user, :owner) }
  let(:organization) { create(:organization, owner: owner) }

  describe "organization isolation" do
    it "never exposes another organization's memberships to an owner" do
      create(:subscription, organization: organization, subscription_plan: create(:subscription_plan))

      other_org = create(:organization)
      other_plan = create(:membership_plan, organization: other_org)
      create(:membership, membership_plan: other_plan)

      get "/api/v1/memberships", headers: auth_headers(owner)

      expect(response.parsed_body["memberships"]).to eq([])
    end
  end

  describe "POST /api/v1/memberships" do
    it "lets the owner give a client a membership, active immediately" do
      plan = create(:membership_plan, organization: organization, active: true, price: 89)
      client = create(:client, organization: organization)

      post "/api/v1/memberships",
           params: { client_id: client.id, membership_plan_id: plan.id, payment_method: "cash", payment_amount: "89" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["membership"]["status"]).to eq("active")
      expect(response.parsed_body["membership"]["payment_status"]).to eq("paid")
      expect(response.parsed_body["payment"]["status"]).to eq("paid")
    end

    it "creates the membership unpaid when no payment is recorded" do
      plan = create(:membership_plan, organization: organization, active: true)
      client = create(:client, organization: organization)

      post "/api/v1/memberships", params: { client_id: client.id, membership_plan_id: plan.id }, headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["membership"]["payment_status"]).to eq("unpaid")
      expect(response.parsed_body["payment"]).to be_nil
    end

    it "forbids a coach from giving a client a membership" do
      plan = create(:membership_plan, organization: organization, active: true)
      client = create(:client, organization: organization)
      coach = create(:staff_member, organization: organization, role: :coach)

      post "/api/v1/memberships", params: { client_id: client.id, membership_plan_id: plan.id }, headers: auth_headers(coach.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/memberships/:id/renew" do
    it "creates a new membership starting when the current one ends, without touching history" do
      plan = create(:membership_plan, organization: organization, duration_days: 30)
      client = create(:client, organization: organization)
      original = create(:membership, client: client, membership_plan: plan, organization: organization,
                                      starts_at: 30.days.ago, expires_at: 1.day.from_now)

      post "/api/v1/memberships/#{original.id}/renew", headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      new_membership = response.parsed_body["membership"]
      expect(new_membership["id"]).not_to eq(original.id)
      expect(client.memberships.count).to eq(2)
      expect(original.reload.status).to eq("active") # history untouched
    end
  end
end
