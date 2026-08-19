class ActivitySerializer
  def initialize(activity)
    @activity = activity
  end

  def as_json(*)
    {
      id: activity.id,
      location_id: activity.location_id,
      name: activity.name,
      emoji: activity.emoji,
      description: activity.description,
      activity_type: activity.activity_type,
      booking_mode: activity.booking_mode,
      duration: activity.duration,
      capacity: activity.capacity,
      active: activity.active
    }
  end

  private

  attr_reader :activity
end
