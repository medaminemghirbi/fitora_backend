class CompanySerializer
  def initialize(company)
    @company = company
  end

  def as_json(*)
    return nil if company.nil?

    {
      id: company.id,
      name: company.name,
      description: company.description,
      phone: company.phone,
      email: company.email,
      country: company.country,
      city: company.city,
      address: company.address,
      latitude: company.latitude,
      longitude: company.longitude,
      timezone: company.timezone,
      currency: company.currency,
      active: company.active
    }
  end

  private

  attr_reader :company
end
