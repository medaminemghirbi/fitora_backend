class StaffMemberSerializer
  def initialize(staff_member)
    @staff_member = staff_member
  end

  def as_json(*)
    {
      id: staff_member.id,
      role: staff_member.role,
      active: staff_member.active,
      user: {
        id: staff_member.user.id,
        full_name: staff_member.user.full_name,
        email: staff_member.user.email,
        phone: staff_member.user.phone
      },
      coach_id: staff_member.coach_id,
      location_ids: staff_member.location_ids
    }
  end

  private

  attr_reader :staff_member
end
