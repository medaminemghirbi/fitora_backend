require "rails_helper"

RSpec.describe Bookings::Create do
  it "confirms a booking when capacity is available" do
    session = create(:session, capacity: 2)
    client = create(:client)

    result = described_class.call(client: client, session: session)

    expect(result.success?).to be true
    expect(result.booking).to be_confirmed
  end

  it "rejects a booking once the session is full" do
    session = create(:session, capacity: 1)
    create(:booking, session: session, status: :confirmed)
    client = create(:client)

    result = described_class.call(client: client, session: session)

    expect(result.success?).to be false
    expect(result.error).to eq("This session is full.")
  end

  it "rejects a duplicate booking by the same client" do
    session = create(:session, capacity: 5)
    client = create(:client)
    create(:booking, session: session, client: client, status: :confirmed)

    result = described_class.call(client: client, session: session)

    expect(result.success?).to be false
    expect(result.error).to eq("This client already has a booking for this session.")
  end

  it "rejects booking a cancelled session" do
    session = create(:session, status: :cancelled)
    client = create(:client)

    result = described_class.call(client: client, session: session)

    expect(result.success?).to be false
    expect(result.error).to eq("This session has been cancelled.")
  end

  it "does not allow bookings to exceed capacity under concurrent requests" do
    session = create(:session, capacity: 1)
    client_a = create(:client)
    client_b = create(:client)

    results = [ client_a, client_b ].map do |client|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(client: client, session: session)
        end
      end
    end.map(&:value)

    successes = results.count(&:success?)
    expect(successes).to eq(1)
    expect(session.reload.confirmed_bookings_count).to eq(1)
  end
end
