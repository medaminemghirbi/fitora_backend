require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:owner) { create(:user, :owner) }
  let!(:company) { create(:company, owner: owner) }
  let!(:location) { create(:location, company: company) }
  let!(:activity) { create(:activity, location: location) }

  describe "GET /api/v1/sessions" do
    it "never exposes another company's sessions" do
      create(:session, activity: activity, location: location)
      other_activity = create(:activity)
      other_session = create(:session, activity: other_activity, location: other_activity.location)

      get "/api/v1/sessions", headers: auth_headers(owner)

      ids = response.parsed_body["sessions"].map { |s| s["id"] }
      expect(ids).not_to include(other_session.id)
    end

    it "limits a coach to only their own sessions" do
      coach = create(:coach, company: company)
      create(:coach_location, coach: coach, location: location)
      coach_staff = create(:staff_member, company: company, role: :coach, coach: coach)
      own_session = create(:session, activity: activity, location: location, coach: coach)
      other_coach_session = create(:session, activity: activity, location: location)

      get "/api/v1/sessions", headers: auth_headers(coach_staff.user)

      ids = response.parsed_body["sessions"].map { |s| s["id"] }
      expect(ids).to include(own_session.id)
      expect(ids).not_to include(other_coach_session.id)
    end
  end

  describe "GET /api/v1/sessions/:id" do
    it "404s for a session belonging to another company" do
      other_activity = create(:activity)
      other_session = create(:session, activity: other_activity, location: other_activity.location)

      get "/api/v1/sessions/#{other_session.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/sessions/:id" do
    it "rejects updates to another company's session" do
      other_activity = create(:activity)
      other_session = create(:session, activity: other_activity, location: other_activity.location)

      patch "/api/v1/sessions/#{other_session.id}", params: { session: { capacity: 99 } }, headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end
end
