class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      locale: user.locale,
      organization_id: user.organization&.id || user.staff_member&.organization_id,
      staff_role: user.staff_member&.role
    }
  end

  private

  attr_reader :user
end
