class PackageSerializer
  def initialize(package)
    @package = package
  end

  def as_json(*)
    {
      id: package.id,
      organization_id: package.organization_id,
      activity_id: package.activity_id,
      activity_name: package.activity&.name,
      name: package.name,
      description: package.description,
      price: package.price,
      currency: package.currency,
      credits: package.credits,
      validity_days: package.validity_days,
      active: package.active
    }
  end

  private

  attr_reader :package
end
