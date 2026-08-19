require "rails_helper"

RSpec.describe "Api::V1::Admin::Payments", type: :request do
  let(:admin) { create(:user, :admin) }

  it "forbids non-admins" do
    owner = create(:user, :owner)

    get "/api/v1/admin/payments", headers: auth_headers(owner)

    expect(response).to have_http_status(:forbidden)
  end

  it "lists payments across every company, not scoped to one" do
    org_a = create(:company)
    org_b = create(:company)
    payment_a = create(:payment, company: org_a, client: create(:client, company: org_a))
    payment_b = create(:payment, company: org_b, client: create(:client, company: org_b))

    get "/api/v1/admin/payments", headers: auth_headers(admin)

    ids = response.parsed_body["payments"].map { |p| p["id"] }
    expect(ids).to include(payment_a.id, payment_b.id)
  end

  it "filters by company_id" do
    org_a = create(:company)
    org_b = create(:company)
    payment_a = create(:payment, company: org_a, client: create(:client, company: org_a))
    create(:payment, company: org_b, client: create(:client, company: org_b))

    get "/api/v1/admin/payments", params: { company_id: org_a.id }, headers: auth_headers(admin)

    ids = response.parsed_body["payments"].map { |p| p["id"] }
    expect(ids).to eq([ payment_a.id ])
  end
end
