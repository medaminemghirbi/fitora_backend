class AppointmentSerializer
  def initialize(appointment)
    @appointment = appointment
  end

  def as_json(*)
    {
      id: appointment.id,
      starts_at: appointment.starts_at,
      ends_at: appointment.ends_at,
      status: appointment.status,
      title: appointment.label,
      notes: appointment.notes,
      client_id: appointment.client_id,
      client_name: appointment.client&.full_name,
      staff_member_id: appointment.staff_member_id,
      staff_member_name: appointment.staff_member&.user&.full_name,
      appointment_type_id: appointment.appointment_type_id,
      appointment_type_name: appointment.appointment_type&.name,
      color: appointment.appointment_type&.color || "#4f46e5",
      location_id: appointment.location_id
    }
  end

  private

  attr_reader :appointment
end
