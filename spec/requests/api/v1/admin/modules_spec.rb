require "rails_helper"

RSpec.describe "Api::V1::Admin::Modules", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/admin/modules" do
    it "lists the optional module catalogue with prices and usage counts" do
      c1 = create(:company)
      c2 = create(:company)
      c2.company_modules.find_by(key: "fitness").update!(enabled: false)

      get "/api/v1/admin/modules", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      mods = response.parsed_body["modules"].index_by { |m| m["key"] }
      expect(mods.keys).to match_array(ModuleRegistry::OPTIONAL_KEYS)
      expect(mods["fitness"]).to include("name", "price_cents", "currency", "active")
      expect(mods["fitness"]["companies_count"]).to eq(1)   # only c1
      expect(mods["hr"]["companies_count"]).to eq(2)
    end

    it "is admin-only" do
      get "/api/v1/admin/modules", headers: auth_headers(create(:user, :owner))
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/admin/modules/:key" do
    it "updates the price and active flag" do
      patch "/api/v1/admin/modules/fitness",
            params: { price_cents: 4500, active: false }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      row = PlatformModulePrice.for("fitness")
      expect(row.price_cents).to eq(4500)
      expect(row.active).to be(false)
    end

    it "rejects a negative price" do
      patch "/api/v1/admin/modules/fitness", params: { price_cents: -1 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "404s on an unknown / non-optional module" do
      patch "/api/v1/admin/modules/core", params: { price_cents: 100 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end
  end
end
