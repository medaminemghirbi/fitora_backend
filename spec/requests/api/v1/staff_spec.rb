require "rails_helper"

RSpec.describe "Api::V1::Staff", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }

  describe "authorization" do
    it "lets the owner create a staff member" do
      post "/api/v1/staff",
           params: { staff_member: { first_name: "Sara", last_name: "Manager", email: "sara@gerily.test", password: "password123", role: "manager" } },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["staff_member"]["role"]).to eq("manager")
    end

    it "is never blocked by any staff count — no plans, no limits" do
      create_list(:staff_member, 5, company: company)

      post "/api/v1/staff",
           params: { staff_member: { first_name: "Sara", last_name: "Manager", email: "sara@gerily.test", password: "password123", role: "manager" } },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
    end

    it "forbids a manager from creating staff — only the owner manages staff now" do
      manager = create(:staff_member, company: company, role: :manager)

      post "/api/v1/staff",
           params: { staff_member: { first_name: "New", last_name: "Hire", email: "hire2@gerily.test", password: "password123", role: "coach" } },
           headers: auth_headers(manager.user)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a coach from creating staff" do
      coach_staff = create(:staff_member, company: company, role: :coach)

      post "/api/v1/staff",
           params: { staff_member: { first_name: "New", last_name: "Hire", email: "hire3@gerily.test", password: "password123", role: "coach" } },
           headers: auth_headers(coach_staff.user)

      expect(response).to have_http_status(:forbidden)
    end

    it "the Gerily platform admin (User#role == admin) has no special access to an company's staff endpoint" do
      platform_admin = create(:user, :admin)

      get "/api/v1/staff", headers: auth_headers(platform_admin)

      # The platform admin has no company of their own, so this 422s on
      # require_company! rather than ever leaking another org's staff.
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "audit logging" do
    it "logs a staff role change" do
      staff = create(:staff_member, company: company, role: :manager)

      patch "/api/v1/staff/#{staff.id}", params: { staff_member: { role: "receptionist" } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      log = AuditLog.last
      expect(log.action).to eq("staff.role_changed")
      expect(log.company_id).to eq(company.id)
    end
  end

  describe "company isolation" do
    it "never exposes another company's staff" do
      other_org_staff = create(:staff_member)

      get "/api/v1/staff", headers: auth_headers(owner)

      ids = response.parsed_body["staff"].map { |s| s["id"] }
      expect(ids).not_to include(other_org_staff.id)
    end
  end
end
