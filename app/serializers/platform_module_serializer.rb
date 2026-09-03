class PlatformModuleSerializer
  def initialize(row, companies_count: nil)
    @row = row
    @companies_count = companies_count
  end

  def as_json(*)
    {
      key: row.key,
      name: row.name,
      description: row.description,
      price_cents: row.price_cents,
      currency: row.currency,
      active: row.active,
      companies_count: companies_count
    }.compact
  end

  private

  attr_reader :row, :companies_count
end
