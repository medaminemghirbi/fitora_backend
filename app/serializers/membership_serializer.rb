class MembershipSerializer
  def initialize(membership)
    @membership = membership
  end

  def as_json(*)
    return nil if membership.nil?

    {
      id: membership.id,
      status: membership.status,
      starts_at: membership.starts_at,
      expires_at: membership.expires_at,
      remaining_bookings: membership.remaining_bookings,
      auto_renew: membership.auto_renew,
      discount: membership.discount,
      final_price: membership.final_price,
      payment_status: membership.payment_status,
      plan: MembershipPlanSerializer.new(membership.membership_plan).as_json,
      client: { id: membership.client.id, full_name: membership.client.full_name, phone: membership.client.phone }
    }
  end

  private

  attr_reader :membership
end
