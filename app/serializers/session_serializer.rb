class SessionSerializer
  def initialize(session, current_user: nil)
    @session = session
    @current_user = current_user
  end

  def as_json(*)
    {
      id: session.id,
      activity_id: session.activity_id,
      activity_name: session.activity.name,
      activity_emoji: session.activity.emoji,
      booking_mode: session.activity.booking_mode,
      location_id: session.location_id,
      location_name: session.location.name,
      coach_id: session.coach_id,
      coach_name: session.coach&.full_name,
      starts_at: session.starts_at,
      ends_at: session.ends_at,
      capacity: session.capacity,
      confirmed_count: session.confirmed_bookings_count,
      price: session.price,
      status: session.status,
      availability: availability,
      already_booked: already_booked?
    }
  end

  private

  attr_reader :session, :current_user

  def availability
    return "cancelled" if session.cancelled?
    return "full" if session.full?

    "available"
  end

  def already_booked?
    return false if current_user.nil?

    session.bookings.held.where(user_id: current_user.id).exists?
  end
end
