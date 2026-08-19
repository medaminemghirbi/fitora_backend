require "rails_helper"

RSpec.describe Memberships::Renew do
  it "creates a new membership starting exactly when the current one expires, never touching history" do
    plan = create(:membership_plan, duration_days: 30)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)
    original = create(:membership, client: client, membership_plan: plan, organization: plan.organization,
                                    starts_at: 30.days.ago, expires_at: 5.days.from_now)

    result = described_class.call(membership: original, created_by: staff)

    expect(result.success?).to be true
    expect(result.membership.id).not_to eq(original.id)
    expect(result.membership.starts_at.to_date).to eq(original.expires_at.to_date)
    expect(result.membership.expires_at.to_date).to eq(original.expires_at.to_date + 30.days)
    expect(original.reload.status).to eq("active")
  end

  it "starts the new membership today when the current one has already expired" do
    plan = create(:membership_plan, duration_days: 30)
    client = create(:client, organization: plan.organization)
    staff = create(:user, :owner)
    original = create(:membership, client: client, membership_plan: plan, organization: plan.organization,
                                    starts_at: 40.days.ago, expires_at: 10.days.ago, status: :expired)

    result = described_class.call(membership: original, created_by: staff)

    expect(result.membership.starts_at.to_date).to eq(Date.current)
  end
end
