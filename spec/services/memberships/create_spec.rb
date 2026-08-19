require "rails_helper"

RSpec.describe Memberships::Create do
  it "creates an active membership with expires_at derived from the plan's duration" do
    plan = create(:membership_plan, duration_days: 30, price: 89)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)

    starts_on = Date.current
    result = described_class.call(client: client, membership_plan: plan, created_by: staff, starts_on: starts_on)

    expect(result.success?).to be true
    expect(result.membership).to be_active
    expect(result.membership.expires_at.to_date).to eq(starts_on + 30.days)
    expect(result.membership.final_price).to eq(89)
  end

  it "applies a discount to the final price" do
    plan = create(:membership_plan, price: 100)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)

    result = described_class.call(client: client, membership_plan: plan, created_by: staff, discount: 20)

    expect(result.membership.final_price).to eq(80)
  end

  it "records a payment and marks the membership fully paid when the payment covers the final price" do
    plan = create(:membership_plan, price: 89)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)

    result = described_class.call(client: client, membership_plan: plan, created_by: staff, payment_method: "card", payment_amount: "89")

    expect(result.payment).to be_present
    expect(result.payment).to be_paid
    expect(result.membership).to be_paid
  end

  it "marks the membership partially paid when the payment is less than the final price" do
    plan = create(:membership_plan, price: 89)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)

    result = described_class.call(client: client, membership_plan: plan, created_by: staff, payment_method: "cash", payment_amount: "40")

    expect(result.membership).to be_partial
  end

  it "leaves the membership unpaid and creates no payment when no payment is recorded" do
    plan = create(:membership_plan, price: 89)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)

    result = described_class.call(client: client, membership_plan: plan, created_by: staff)

    expect(result.payment).to be_nil
    expect(result.membership).to be_unpaid
  end
end
