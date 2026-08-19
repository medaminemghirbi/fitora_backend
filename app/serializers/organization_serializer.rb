class OrganizationSerializer
  def initialize(organization)
    @organization = organization
  end

  def as_json(*)
    return nil if organization.nil?

    {
      id: organization.id,
      name: organization.name,
      description: organization.description,
      phone: organization.phone,
      email: organization.email,
      country: organization.country,
      city: organization.city,
      address: organization.address,
      latitude: organization.latitude,
      longitude: organization.longitude,
      timezone: organization.timezone,
      currency: organization.currency,
      active: organization.active
    }
  end

  private

  attr_reader :organization
end
