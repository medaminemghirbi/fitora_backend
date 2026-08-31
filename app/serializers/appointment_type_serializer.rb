class AppointmentTypeSerializer
  def initialize(appointment_type)
    @appointment_type = appointment_type
  end

  def as_json(*)
    {
      id: appointment_type.id,
      name: appointment_type.name,
      duration_minutes: appointment_type.duration_minutes,
      color: appointment_type.color,
      active: appointment_type.active,
      position: appointment_type.position
    }
  end

  private

  attr_reader :appointment_type
end
