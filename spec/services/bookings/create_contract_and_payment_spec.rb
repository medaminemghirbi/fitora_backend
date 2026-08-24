require "rails_helper"

RSpec.describe "Bookings::Create — contract coverage and unpaid bookings" do
  describe "contract_required activities" do
    it "confirms instantly and consumes a booking credit when the client has a covering contract" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :contract_required)
      plan = create(:contract_type, company: session.location.company, unlimited_bookings: false, booking_limit: 3)
      contract = create(:contract, contract_type: plan, remaining_bookings: 3)

      result = Bookings::Create.call(client: contract.client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking.contract_period.contract).to eq(contract)
      expect(result.booking).to be_paid
      expect(contract.reload.remaining_bookings).to eq(2)
    end

    it "rejects the booking with a friendly error when there is no covering contract" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :contract_required)
      client = create(:client)

      result = Bookings::Create.call(client: client, session: session)

      expect(result.success?).to be false
      expect(result.error).to eq("This client needs an active contract to book this activity.")
    end

    it "does not grant access from a contract plan scoped to a different activity" do
      session = create(:session, capacity: 5)
      session.activity.update!(booking_mode: :contract_required)
      other_activity = create(:activity, location: session.location)
      plan = create(:contract_type, company: session.location.company, unlimited_bookings: true)
      plan.activity_ids = [ other_activity.id ]
      contract = create(:contract, contract_type: plan)

      result = Bookings::Create.call(client: contract.client, session: session)

      expect(result.success?).to be false
    end
  end

  describe "pay_per_booking activities" do
    it "consumes a booking credit instead of charging when the client has a covering contract" do
      session = create(:session, capacity: 5, price: 40)
      session.activity.update!(booking_mode: :pay_per_booking)
      plan = create(:contract_type, company: session.location.company, unlimited_bookings: false, booking_limit: 3)
      contract = create(:contract, contract_type: plan, remaining_bookings: 3)

      result = Bookings::Create.call(client: contract.client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking.amount).to eq(0)
      expect(contract.reload.remaining_bookings).to eq(2)
    end

    it "confirms the booking unpaid, with no inline payment, when there is no contract coverage" do
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

    it "confirms free activities exactly as before, ignoring contract state" do
      session = create(:session, capacity: 5)
      client = create(:client)

      result = Bookings::Create.call(client: client, session: session)

      expect(result.success?).to be true
      expect(result.booking).to be_confirmed
      expect(result.booking).to be_paid
    end
  end
end
