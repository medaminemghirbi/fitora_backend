require "rails_helper"

RSpec.describe "Bookings::Create — membership/package coverage and unpaid bookings" do
  describe "membership_required activities" do
    it "confirms instantly and consumes a booking credit when the client has a covering membership" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :membership_required)
      plan = create(:membership_plan, organization: session.location.organization, unlimited_bookings: false, booking_limit: 3)
      membership = create(:membership, membership_plan: plan, remaining_bookings: 3)

      result = Bookings::Create.call(client: membership.client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking.membership).to eq(membership)
      expect(result.booking).to be_paid
      expect(membership.reload.remaining_bookings).to eq(2)
    end

    it "rejects the booking with a friendly error when there is no covering membership" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :membership_required)
      client = create(:client)

      result = Bookings::Create.call(client: client, session: session)

      expect(result.success?).to be false
      expect(result.error).to eq("This client needs an active membership to book this activity.")
    end

    it "does not grant access from a membership plan scoped to a different activity" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :membership_required)
      other_activity = create(:activity, location: session.location)
      plan = create(:membership_plan, organization: session.location.organization, unlimited_bookings: true)
      plan.activity_ids = [ other_activity.id ]
      membership = create(:membership, membership_plan: plan)

      result = Bookings::Create.call(client: membership.client, session: session)

      expect(result.success?).to be false
    end
  end

  describe "pay_per_booking activities" do
    it "consumes a package credit instead of charging when the client has one" do
      session = create(:session, capacity: 5, price: 40)
      session.activity.update!(booking_mode: :pay_per_booking)
      client_package = create(:client_package, remaining_credits: 3)
      client_package.package.update!(organization: session.location.organization, activity: nil)

      result = Bookings::Create.call(client: client_package.client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking.amount).to eq(0)
      expect(client_package.reload.remaining_credits).to eq(2)
    end

    it "confirms the booking unpaid, with no inline payment, when there is no membership or package coverage" do
      session = create(:session, capacity: 5, price: 40)
      session.activity.update!(booking_mode: :pay_per_booking)
      client = create(:client)

      result = Bookings::Create.call(client: client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking.amount).to eq(40)
      expect(result.booking).to be_unpaid
      expect(Payment.count).to eq(0)
    end

    it "confirms free activities exactly as before, ignoring membership/package state" do
      session = create(:session, capacity: 5)
      client = create(:client)

      result = Bookings::Create.call(client: client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking).to be_paid
    end
  end
end
