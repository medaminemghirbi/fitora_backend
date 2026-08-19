class ContractPlanSerializer
  def initialize(plan)
    @plan = plan
  end

  def as_json(*)
    {
      id: plan.id,
      name: plan.name,
      code: plan.code,
      max_locations: plan.max_locations,
      max_clients: plan.max_clients,
      max_staff: plan.max_staff,
      price: plan.price,
      billing_period: plan.billing_period
    }
  end

  private

  attr_reader :plan
end
