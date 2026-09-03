class AdminCompanySerializer
  def initialize(company)
    @company = company
  end

  def as_json(*)
    enabled = company.enabled_module_keys
    prices = PlatformModulePrice.catalog.index_by(&:key)

    {
      id: company.id,
      name: company.name,
      city: company.city,
      country: company.country,
      currency: company.currency,
      currency_symbol: company.currency_symbol,
      locale: company.locale,
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
      subscription: SubscriptionSerializer.new(company.subscription).as_json,
      monthly_total_cents: company.monthly_total_cents,
      # The optional-module catalogue with this company's enabled flag + the
      # platform price — the checklist the admin edits.
      modules: ModuleRegistry::OPTIONAL_KEYS.map do |key|
        price = prices[key]
        {
          key: key,
          name: ModuleRegistry::CATALOG.dig(key, :name),
          description: ModuleRegistry::CATALOG.dig(key, :description),
          enabled: enabled.include?(key),
          price_cents: price&.price_cents || 0,
          currency: price&.currency || "TND",
          available: price&.active != false
        }
      end
    }
  end

  private

  attr_reader :company
end
