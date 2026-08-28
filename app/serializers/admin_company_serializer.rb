class AdminCompanySerializer
  def initialize(company)
    @company = company
  end

  def as_json(*)
    {
      id: company.id,
      name: company.name,
      city: company.city,
      country: company.country,
      currency: company.currency,
      active: company.active,
      mobile_auth_key: company.mobile_auth_key,
      created_at: company.created_at,
      locations_count: company.locations.count,
      trial_locked: company.subscription&.locked? || false,
      trial_days_remaining: company.subscription&.days_remaining,
      owner: {
        id: company.owner.id,
        full_name: company.owner.full_name,
        email: company.owner.email,
        phone: company.owner.phone
      },
      subscription: SubscriptionSerializer.new(company.subscription).as_json
    }
  end

  private

  attr_reader :company
end
