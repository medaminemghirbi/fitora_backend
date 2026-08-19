class AdminOrganizationSerializer
  def initialize(organization)
    @organization = organization
  end

  def as_json(*)
    {
      id: organization.id,
      name: organization.name,
      city: organization.city,
      country: organization.country,
      currency: organization.currency,
      active: organization.active,
      created_at: organization.created_at,
      locations_count: organization.locations.count,
      trial_locked: organization.subscription&.locked? || false,
      trial_days_remaining: organization.subscription&.days_remaining,
      owner: {
        id: organization.owner.id,
        full_name: organization.owner.full_name,
        email: organization.owner.email,
        phone: organization.owner.phone
      },
      subscription: SubscriptionSerializer.new(organization.subscription).as_json
    }
  end

  private

  attr_reader :organization
end
