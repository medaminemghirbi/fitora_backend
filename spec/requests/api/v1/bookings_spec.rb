require "rails_helper"

RSpec.describe "Api::V1::Bookings", type: :request do
  let(:owner) { create(:user, :owner) }
  let(:organization) { create(:organization, owner: owner) }
  let(:location) { create(:location, organization: organization) }
  let(:activity) { create(:activity, location: location) }
  let(:session) { create(:session, activity: activity, location: location, capacity: 1) }
  let(:client) { create(:client, organization: organization) }

  describe "POST /api/v1/bookings" do
    it "lets the owner book a client into a session" do
      post "/api/v1/bookings", params: { client_id: client.id, session_id: session.id }, headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["booking"]["status"]).to eq("confirmed")
      expect(response.parsed_body["booking"]["client"]["id"]).to eq(client.id)
    end

    it "lets a manager with the bookings capability book a client" do
      manager = create(:staff_member, organization: organization, role: :manager)

      post "/api/v1/bookings", params: { client_id: client.id, session_id: session.id }, headers: auth_headers(manager.user)

      expect(response).to have_http_status(:created)
    end

    it "forbids a coach from booking a client (no bookings capability)" do
      coach = create(:staff_member, organization: organization, role: :coach)

      post "/api/v1/bookings", params: { client_id: client.id, session_id: session.id }, headers: auth_headers(coach.user)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns a friendly error when the session is full" do
      create(:booking, client: create(:client, organization: organization), session: session, status: :confirmed)

      post "/api/v1/bookings", params: { client_id: client.id, session_id: session.id }, headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("This session is full.")
    end
  end

  describe "POST /api/v1/bookings/:id/cancel" do
    it "lets the owner cancel a client's booking" do
      booking = create(:booking, client: client, session: session)

      post "/api/v1/bookings/#{booking.id}/cancel", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["booking"]["status"]).to eq("cancelled")
    end

    it "forbids another organization's owner from cancelling this booking" do
      other_owner = create(:user, :owner)
      create(:organization, owner: other_owner)
      booking = create(:booking, client: client, session: session)

      post "/api/v1/bookings/#{booking.id}/cancel", headers: auth_headers(other_owner)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/bookings" do
    it "only returns the organization's own bookings" do
      create(:booking, client: client, session: session)
      create(:booking, client: create(:client), session: create(:session, capacity: 5))

      get "/api/v1/bookings", headers: auth_headers(owner)

      body = response.parsed_body["bookings"]
      expect(body.size).to eq(1)
      expect(body.first["client"]["id"]).to eq(client.id)
    end

    it "narrows a coach to bookings on their own sessions" do
      coach_profile = create(:coach, organization: organization)
      create(:coach_location, coach: coach_profile, location: location)
      coach_staff = create(:staff_member, organization: organization, role: :coach, coach: coach_profile)
      own_session = create(:session, activity: activity, location: location, coach: coach_profile)
      other_session = create(:session, activity: activity, location: location)
      create(:booking, client: client, session: own_session)
      create(:booking, client: client, session: other_session)

      get "/api/v1/bookings", headers: auth_headers(coach_staff.user)

      expect(response.parsed_body["bookings"].size).to eq(1)
    end
  end
end
