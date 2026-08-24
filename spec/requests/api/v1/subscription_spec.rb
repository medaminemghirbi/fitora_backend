require "rails_helper"

RSpec.describe "Api::V1::Subscription", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "GET /api/v1/subscription" do
    it "reports the company's status and trial countdown" do
      create(:subscription, company: company, status: :active, starts_at: 1.day.ago, expires_at: 13.days.from_now)

      get "/api/v1/subscription", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body["subscription"]
      expect(json["status"]).to eq("active")
      expect(response.parsed_body["trial_days_remaining"]).to eq(13)
      expect(response.parsed_body["locked"]).to be false
    end

    it "forbids staff — this is the owner's own account status" do
      staff = create(:staff_member, company: company)

      get "/api/v1/subscription", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
