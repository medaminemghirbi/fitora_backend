require "rails_helper"

RSpec.describe Contracts::Create do
  it "creates an active contract with expires_at derived from the plan's duration" do
    plan = create(:contract_type, price: 89)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    starts_on = Date.current
    result = described_class.call(client: client, contract_type: plan, created_by: staff, starts_on: starts_on)

    expect(result.success?).to be true
    expect(result.contract).to be_active
    expect(result.contract.expires_at.to_date).to eq(starts_on + 30.days)
    expect(result.contract.final_price).to eq(89)
  end

  it "applies a discount to the final price" do
    plan = create(:contract_type, price: 100)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    result = described_class.call(client: client, contract_type: plan, created_by: staff, discount: 20)

    expect(result.contract.final_price).to eq(80)
  end

  it "records a payment and marks the contract fully paid when the payment covers the final price" do
    plan = create(:contract_type, price: 89)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    result = described_class.call(client: client, contract_type: plan, created_by: staff, payment_method: "bank_transfer", payment_amount: "89")

    expect(result.payment).to be_present
    expect(result.payment).to be_paid
    expect(result.contract).to be_paid
  end

  it "falls back to cash when given an unsupported payment method (card is out of scope)" do
    plan = create(:contract_type, price: 50)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    result = described_class.call(client: client, contract_type: plan, created_by: staff, payment_method: "card", payment_amount: "50")

    expect(result.payment).to be_paid
    expect(result.payment.payment_method).to eq("cash")
  end

  it "marks the contract partially paid when the payment is less than the final price" do
    plan = create(:contract_type, price: 89)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    result = described_class.call(client: client, contract_type: plan, created_by: staff, payment_method: "cash", payment_amount: "40")

    expect(result.contract).to be_partial
  end

  it "leaves the contract unpaid and creates no payment when no payment is recorded" do
    plan = create(:contract_type, price: 89)
    client = create(:client, company: plan.company)
    staff = create(:user, :owner)

    result = described_class.call(client: client, contract_type: plan, created_by: staff)

    expect(result.payment).to be_nil
    expect(result.contract).to be_unpaid
  end
end
