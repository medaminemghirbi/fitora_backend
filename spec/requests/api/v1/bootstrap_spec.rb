require "rails_helper"

RSpec.describe "Api::V1 GET /api/v1/bootstrap", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }
  let!(:subscription) { create(:subscription, company: company, expires_at: 5.days.from_now) }

  it "hydrates the owner shell in one call" do
    get "/api/v1/bootstrap", headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["user"]["id"]).to eq(owner.id)
    expect(body["company"]["id"]).to eq(company.id)
    expect(body["branding"]["name"]).to eq(company.name)
    expect(body["role"]["key"]).to eq("owner")
    expect(body["permissions"]).to match_array(Permission::ALL)
    expect(body["modules"]).to match_array(%w[core fitness])
    expect(body["subscription"]).to include("status", "locked", "trial_days_remaining")
  end

  it "hides the full company profile from staff but still returns branding" do
    staff = create(:staff_member, company: company, role: :receptionist)

    get "/api/v1/bootstrap", headers: auth_headers(staff.user)

    body = response.parsed_body
    expect(body["company"]).to be_nil
    expect(body["branding"]["name"]).to eq(company.name)
    expect(body["permissions"]).to include("bookings")
  end

  it "drops a disabled module's permissions" do
    company.company_modules.find_by(key: "fitness").update!(enabled: false)

    get "/api/v1/bootstrap", headers: auth_headers(owner)

    body = response.parsed_body
    expect(body["modules"]).to eq(%w[core])
    expect(body["permissions"]).not_to include("sessions", "contracts", "bookings")
    expect(body["permissions"]).to include("clients", "payments")
  end

  it "still bootstraps a locked company (for the trial-expired screen)" do
    subscription.update!(status: :active, expires_at: 2.days.ago)

    get "/api/v1/bootstrap", headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["subscription"]["locked"]).to be(true)
  end
end
