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
      expires_at: subscription.expires_at
    }
  end

  private

  attr_reader :subscription
end
