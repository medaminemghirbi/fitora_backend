module Memberships
  class Renew
    Result = Struct.new(:success?, :membership, :error, keyword_init: true)

    def self.call(membership:, created_by:)
      new(membership: membership, created_by: created_by).call
    end

    def initialize(membership:, created_by:)
      @membership = membership
      @created_by = created_by
    end

    # Always creates a NEW membership row — history is never mutated, per the
    # product spec's "never destroy membership history."
    def call
      plan = membership.membership_plan
      starts_at = [ membership.expires_at, Time.current ].compact.max

      new_membership = Membership.create!(
        client: membership.client,
        membership_plan: plan,
        company: membership.company,
        status: :active,
        starts_at: starts_at,
        expires_at: starts_at + plan.duration_days.days,
        remaining_bookings: plan.unlimited_bookings? ? nil : plan.booking_limit,
        discount: membership.discount,
        created_by: created_by
      )

      Result.new(success?: true, membership: new_membership, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, membership: nil, error: e.record.errors.full_messages.first)
    end

    private

    attr_reader :membership, :created_by
  end
end
