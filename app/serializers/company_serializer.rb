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
      currency_symbol: company.currency_symbol,
      locale: company.locale,
      working_days: company.working_days,
      active: company.active,
      slug: company.slug,
      primary_color: company.primary_color,
      logo_url: logo_url,
      mobile_auth_key: company.mobile_auth_key,
      nav_labels: company.nav_labels,
      modules: modules,
      monthly_total_cents: company.monthly_total_cents,
      industry: company.industry,
      industry_options: IndustryPreset.options
    }
  end

  private

  attr_reader :company

  def modules
    enabled = company.enabled_module_keys
    prices = PlatformModulePrice.catalog.index_by(&:key)
    ModuleRegistry::CATALOG.map do |key, meta|
      price = prices[key]
      {
        key: key,
        name: meta[:name],
        description: meta[:description],
        optional: !meta[:always_on],
        enabled: enabled.include?(key),
        price_cents: price&.price_cents || 0,
        currency: price&.currency || "TND"
      }
    end
  end

  def logo_url
    return nil unless company.logo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(company.logo, only_path: true)
  end
end
