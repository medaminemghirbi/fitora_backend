module Memberships
  class Create
    Result = Struct.new(:success?, :membership, :payment, :error, keyword_init: true)

    def self.call(client:, membership_plan:, created_by:, starts_on: Date.current, discount: 0,
                   payment_method: nil, payment_amount: nil, payment_notes: nil)
      new(client: client, membership_plan: membership_plan, created_by: created_by, starts_on: starts_on,
          discount: discount, payment_method: payment_method, payment_amount: payment_amount, payment_notes: payment_notes).call
    end

    def initialize(client:, membership_plan:, created_by:, starts_on:, discount:, payment_method:, payment_amount:, payment_notes:)
      @client = client
      @membership_plan = membership_plan
      @created_by = created_by
      @starts_on = starts_on
      @discount = discount
      @payment_method = payment_method
      @payment_amount = payment_amount
      @payment_notes = payment_notes
    end

    def call
      membership = nil
      payment = nil

      ActiveRecord::Base.transaction do
        # Date#to_time would resolve "starts_on" in the system's local
        # timezone rather than Time.zone, silently shifting the date by a day
        # whenever they differ — in_time_zone is the zone-aware conversion.
        starts_at = starts_on.in_time_zone

        membership = Membership.create!(
          client: client,
          membership_plan: membership_plan,
          company: membership_plan.company,
          status: :active,
          starts_at: starts_at,
          expires_at: starts_at + membership_plan.duration_days.days,
          remaining_bookings: membership_plan.unlimited_bookings? ? nil : membership_plan.booking_limit,
          discount: discount,
          created_by: created_by
        )

        payment = record_payment(membership) if payment_amount.present? && payment_amount.to_f > 0
      end

      Result.new(success?: true, membership: membership, payment: payment, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, membership: nil, payment: nil, error: e.record.errors.full_messages.first)
    end

    private

    attr_reader :client, :membership_plan, :created_by, :starts_on, :discount, :payment_method, :payment_amount, :payment_notes

    def record_payment(membership)
      payment = Payment.create!(
        client: client,
        company: membership_plan.company,
        membership: membership,
        amount: payment_amount,
        currency: membership_plan.currency,
        payment_method: payment_method.presence || :cash,
        status: :paid,
        paid_at: Time.current,
        notes: payment_notes,
        created_by: created_by
      )

      fully_paid = payment_amount.to_f >= membership.final_price.to_f
      membership.update!(payment_status: fully_paid ? :paid : :partial)
      payment
    end
  end
end
