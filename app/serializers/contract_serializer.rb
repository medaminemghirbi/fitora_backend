class ContractSerializer
  def initialize(contract)
    @contract = contract
  end

  def as_json(*)
    return nil if contract.nil?

    {
      id: contract.id,
      current_period_id: contract.current_period&.id,
      status: contract.status,
      starts_at: contract.starts_at,
      expires_at: contract.expires_at,
      remaining_bookings: contract.remaining_bookings,
      auto_renew: contract.auto_renew,
      discount: contract.discount,
      final_price: contract.final_price,
      payment_status: contract.payment_status,
      plan: ContractTypeSerializer.new(contract.contract_type).as_json,
      client: { id: contract.client.id, full_name: contract.client.full_name, phone: contract.client.phone }
    }
  end

  private

  attr_reader :contract
end
