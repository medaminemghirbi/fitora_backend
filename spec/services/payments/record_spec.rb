require "rails_helper"

RSpec.describe Payments::Record do
  it "records a payment against a booking and marks it paid when the amount covers it in full" do
    organization = create(:organization)
    client = create(:client, organization: organization)
    session = create(:session, price: 40)
    booking = create(:booking, client: client, session: session, amount: 40, payment_status: :unpaid)
    staff = create(:user, :owner)

    result = described_class.call(client: client, organization: organization, created_by: staff, amount: 40, payment_method: :cash, booking: booking)

    expect(result.success?).to be true
    expect(booking.reload).to be_paid
  end

  it "accumulates partial payments toward a booking and only flips to paid once fully covered" do
    organization = create(:organization)
    client = create(:client, organization: organization)
    session = create(:session, price: 40)
    booking = create(:booking, client: client, session: session, amount: 40, payment_status: :unpaid)
    staff = create(:user, :owner)

    described_class.call(client: client, organization: organization, created_by: staff, amount: 25, payment_method: :cash, booking: booking)
    expect(booking.reload).to be_partial

    described_class.call(client: client, organization: organization, created_by: staff, amount: 15, payment_method: :card, booking: booking)
    expect(booking.reload).to be_paid
  end

  it "rejects a payment linked to nothing at all" do
    organization = create(:organization)
    client = create(:client, organization: organization)
    staff = create(:user, :owner)

    result = described_class.call(client: client, organization: organization, created_by: staff, amount: 10, payment_method: :cash)

    expect(result.success?).to be false
  end
end
