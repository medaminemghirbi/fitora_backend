class BookingSerializer
  def initialize(booking)
    @booking = booking
  end

  def as_json(*)
    {
      id: booking.id,
      status: booking.status,
      amount: booking.amount,
      currency: booking.currency,
      payment_status: booking.payment_status,
      created_at: booking.created_at,
      covered_by: covered_by,
      client: {
        id: booking.client.id,
        full_name: booking.client.full_name,
        email: booking.client.email,
        phone: booking.client.phone
      },
      session: {
        id: booking.session.id,
        starts_at: booking.session.starts_at,
        ends_at: booking.session.ends_at,
        status: booking.session.status,
        activity_name: booking.session.activity.name,
        activity_emoji: booking.session.activity.emoji,
        location_name: booking.session.location.name,
        coach_name: booking.session.coach&.full_name
      }
    }
  end

  private

  attr_reader :booking

  def covered_by
    return { type: "membership", name: booking.membership.membership_plan.name } if booking.membership
    return { type: "package", name: booking.client_package.package.name } if booking.client_package

    nil
  end
end
