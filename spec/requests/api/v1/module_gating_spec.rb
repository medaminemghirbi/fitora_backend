require "rails_helper"

RSpec.describe "Fitness module API gating", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  context "when the fitness module is enabled (the default)" do
    it "lets the owner reach the fitness endpoints" do
      get "/api/v1/activities", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the fitness module is disabled" do
    before { company.company_modules.find_by(key: "fitness").update!(enabled: false) }

    it "blocks the fitness endpoints with module_not_enabled" do
      %w[/api/v1/activities /api/v1/sessions /api/v1/bookings /api/v1/contracts /api/v1/contract_types].each do |path|
        get path, headers: auth_headers(owner)
        expect(response).to have_http_status(:forbidden), "expected #{path} to be forbidden"
        expect(response.parsed_body["error"]).to eq("module_not_enabled")
      end
    end

    it "still lets the owner reach core endpoints" do
      get "/api/v1/clients", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end
  end
end
