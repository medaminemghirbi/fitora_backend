class ContractSerializer
  def initialize(contract)
    @contract = contract
  end

  def as_json(*)
    return nil if contract.nil?

    {
      id: contract.id,
      status: contract.status,
      starts_at: contract.starts_at,
      expires_at: contract.expires_at,
      auto_renew: contract.auto_renew,
      plan: ContractPlanSerializer.new(contract.contract_plan).as_json
    }
  end

  private

  attr_reader :contract
end
