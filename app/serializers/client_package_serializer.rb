class ClientPackageSerializer
  def initialize(client_package)
    @client_package = client_package
  end

  def as_json(*)
    {
      id: client_package.id,
      status: client_package.status,
      remaining_credits: client_package.remaining_credits,
      purchased_at: client_package.purchased_at,
      expires_at: client_package.expires_at,
      package: PackageSerializer.new(client_package.package).as_json
    }
  end

  private

  attr_reader :client_package
end
