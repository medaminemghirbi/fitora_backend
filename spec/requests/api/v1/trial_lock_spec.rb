require "rails_helper"

RSpec.describe "Free trial lock", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:organization) { create(:organization, owner: owner) }

  describe "an organization still within its trial (or with no deadline at all)" do
    it "is never blocked" do
      create(:subscription, organization: organization, expires_at: 3.days.from_now)

      get "/api/v1/clients", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
    end

    it "with no expires_at at all is never blocked" do
      create(:subscription, organization: organization, expires_at: nil)

      get "/api/v1/clients", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "an organization whose trial has expired" do
    let!(:subscription) { create(:subscription, organization: organization, expires_at: 1.day.ago) }

    it "locks the owner out of ordinary org-scoped endpoints" do
      get "/api/v1/clients", headers: auth_headers(owner)

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body["error"]).to eq("trial_expired")
    end

    it "still lets the owner see their own subscription status" do
      get "/api/v1/subscription", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["locked"]).to be true
    end

    it "still lets the owner submit an upgrade request" do
      plan = create(:subscription_plan)

      post "/api/v1/subscription/upgrade-request",
           params: { plan_id: plan.id, payment_method: "bank_transfer" },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")
    end

    it "still lets the owner see their organization profile" do
      get "/api/v1/organization", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
    end

    it "blocks the owner from editing the organization profile" do
      patch "/api/v1/organization", params: { organization: { name: "New Name" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:payment_required)
    end

    it "locks out staff entirely, with no exceptions" do
      staff = create(:staff_member, organization: organization, role: :manager)

      get "/api/v1/subscription", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:payment_required)
    end

    it "never blocks the platform admin" do
      admin = create(:user, :admin)

      get "/api/v1/admin/organizations", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end

    it "is lifted once a platform admin assigns a plan" do
      admin = create(:user, :admin)
      new_plan = create(:subscription_plan)

      patch "/api/v1/admin/organizations/#{organization.id}/subscription",
            params: { subscription_plan_id: new_plan.id },
            headers: auth_headers(admin)

      expect(subscription.reload.expires_at).to be_nil
      expect(subscription.locked?).to be false

      get "/api/v1/clients", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end
  end
end
