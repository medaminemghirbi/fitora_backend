class SubscriptionSerializer
  def initialize(subscription)
    @subscription = subscription
  end

  def as_json(*)
    return nil if subscription.nil?

    {
      id: subscription.id,
      status: subscription.status,
      starts_at: subscription.starts_at,
      expires_at: subscription.expires_at,
      auto_renew: subscription.auto_renew,
      plan: SubscriptionPlanSerializer.new(subscription.subscription_plan).as_json
    }
  end

  private

  attr_reader :subscription
end
