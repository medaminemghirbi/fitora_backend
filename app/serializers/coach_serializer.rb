class CoachSerializer
  def initialize(coach)
    @coach = coach
  end

  def as_json(*)
    {
      id: coach.id,
      company_id: coach.company_id,
      first_name: coach.first_name,
      last_name: coach.last_name,
      full_name: coach.full_name,
      email: coach.email,
      phone: coach.phone,
      bio: coach.bio,
      photo_url: coach.photo_url,
      active: coach.active,
      location_ids: coach.location_ids
    }
  end

  private

  attr_reader :coach
end
