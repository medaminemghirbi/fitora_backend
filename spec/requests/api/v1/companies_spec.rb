require "rails_helper"

RSpec.describe "Api::V1::Companies", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "GET /api/v1/company" do
    it "returns the owner's company" do
      get "/api/v1/company", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["id"]).to eq(company.id)
    end

    it "forbids staff from reading company settings" do
      staff = create(:staff_member, company: company, role: :manager)

      get "/api/v1/company", headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/company — industry preset at signup" do
    let(:fresh_owner) { create(:user, :owner) }

    it "applies the medical preset: core only, Patients label, renamed roles" do
      post "/api/v1/company",
           params: { company: { name: "Cabinet Nour", timezone: "Africa/Tunis", currency: "TND" }, industry: "medical" },
           headers: auth_headers(fresh_owner)

      expect(response).to have_http_status(:created)
      created = Company.find_by(owner: fresh_owner)
      expect(created.industry).to eq("medical")
      expect(created.enabled_module_keys).to match_array(%w[core appointments])
      expect(created.nav_labels).to include("nav.clients" => "Patients")
      expect(created.roles.find_by(key: "coach").name).to eq("Praticien")
    end

    it "defaults to the generic preset when none is given" do
      post "/api/v1/company",
           params: { company: { name: "Studio X", timezone: "Africa/Tunis", currency: "TND" } },
           headers: auth_headers(fresh_owner)

      expect(Company.find_by(owner: fresh_owner).industry).to eq("generic")
    end
  end

  describe "PATCH /api/v1/company/industry" do
    it "re-applies a preset and is owner-only" do
      patch "/api/v1/company/industry", params: { industry: "legal" }, headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(company.reload.industry).to eq("legal")
      expect(company.roles.find_by(key: "manager").name).to eq("Associé")

      staff = create(:staff_member, company: company, role: :manager)
      patch "/api/v1/company/industry", params: { industry: "medical" }, headers: auth_headers(staff.user)
      expect(response).to have_http_status(:forbidden)
    end

    it "422s on an unknown industry" do
      patch "/api/v1/company/industry", params: { industry: "nope" }, headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/company/modules" do
    it "toggles an optional module and ignores core / unknown keys" do
      patch "/api/v1/company/modules",
            params: { modules: { fitness: false, core: false, teleport: true } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["modules"]).to eq(%w[core])
      expect(company.reload).not_to be_module_enabled("fitness")
      expect(company).to be_module_enabled("core")
    end

    it "is owner-only" do
      staff = create(:staff_member, company: company, role: :manager)
      patch "/api/v1/company/modules", params: { modules: { fitness: false } }, headers: auth_headers(staff.user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/company — module catalog" do
    it "lists every module with its enabled flag" do
      get "/api/v1/company", headers: auth_headers(owner)
      mods = response.parsed_body["company"]["modules"]
      expect(mods.map { |m| m["key"] }).to match_array(ModuleRegistry::KEYS)
      expect(mods.find { |m| m["key"] == "core" }).to include("optional" => false, "enabled" => true)
      expect(mods.find { |m| m["key"] == "appointments" }).to include("optional" => true, "enabled" => false)
    end
  end

  describe "PATCH /api/v1/company — navigation labels" do
    it "stores string overrides and drops blank ones" do
      patch "/api/v1/company",
            params: { company: { nav_labels: { "nav.clients" => "Patients", "nav.contracts" => "  ", "nav.calendar" => "Rendez-vous" } } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(company.reload.nav_labels).to eq("nav.clients" => "Patients", "nav.calendar" => "Rendez-vous")
    end
  end

  describe "PATCH /api/v1/company — branding" do
    it "sets a slug and a primary color" do
      patch "/api/v1/company", params: { company: { slug: "power-gym", primary_color: "#ff5500" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["company"]
      expect(body["slug"]).to eq("power-gym")
      expect(body["primary_color"]).to eq("#ff5500")
    end

    it "uploads a logo" do
      patch "/api/v1/company", params: { company: { logo: fixture_file_upload("sample.png", "image/png") } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["logo_url"]).to be_present
    end

    it "rejects an invalid hex color" do
      patch "/api/v1/company", params: { company: { primary_color: "orange" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a slug with uppercase or spaces" do
      patch "/api/v1/company", params: { company: { slug: "Power Gym" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a slug already used by another company" do
      create(:company, slug: "power-gym")

      patch "/api/v1/company", params: { company: { slug: "power-gym" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "defaults working_days to Monday–Friday" do
      get "/api/v1/company", headers: auth_headers(owner)

      expect(response.parsed_body["company"]["working_days"]).to eq([ 1, 2, 3, 4, 5 ])
    end

    it "updates working_days (a Saturday-opening gym)" do
      patch "/api/v1/company", params: { company: { working_days: [ 6, 1, 2, 3, 4 ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company"]["working_days"]).to eq([ 1, 2, 3, 4, 6 ])
      expect(company.reload.working_days).to eq([ 1, 2, 3, 4, 6 ])
    end

    it "rejects an empty working_days list" do
      patch "/api/v1/company", params: { company: { working_days: [ "" ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an out-of-range weekday" do
      patch "/api/v1/company", params: { company: { working_days: [ 1, 2, 7 ] } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids staff from changing branding" do
      staff = create(:staff_member, company: company, role: :manager)

      patch "/api/v1/company", params: { company: { primary_color: "#ff5500" } }, headers: auth_headers(staff.user)

      expect(response).to have_http_status(:forbidden)
      expect(company.reload.primary_color).to be_nil
    end
  end
end
