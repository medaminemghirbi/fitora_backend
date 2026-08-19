class MembershipPlanSerializer
  def initialize(plan)
    @plan = plan
  end

  def as_json(*)
    {
      id: plan.id,
      organization_id: plan.organization_id,
      name: plan.name,
      description: plan.description,
      price: plan.price,
      currency: plan.currency,
      duration_days: plan.duration_days,
      unlimited_bookings: plan.unlimited_bookings,
      booking_limit: plan.booking_limit,
      priority_booking: plan.priority_booking,
      active: plan.active,
      location_ids: plan.location_ids,
      activity_ids: plan.activity_ids
    }
  end

  private

  attr_reader :plan
end
