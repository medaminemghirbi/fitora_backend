module Payments
  class Record
    Result = Struct.new(:success?, :payment, :error, keyword_init: true)

    def self.call(client:, company:, created_by:, amount:, payment_method:, currency: nil, notes: nil,
                   membership: nil, booking: nil)
      new(client: client, company: company, created_by: created_by, amount: amount, payment_method: payment_method,
          currency: currency, notes: notes, membership: membership, booking: booking).call
    end

    def initialize(client:, company:, created_by:, amount:, payment_method:, currency:, notes:, membership:, booking:)
      @client = client
      @company = company
      @created_by = created_by
      @amount = amount
      @payment_method = payment_method
      @currency = currency || company.currency
      @notes = notes
      @membership = membership
      @booking = booking
    end

    def call
      payment = nil

      ActiveRecord::Base.transaction do
        payment = Payment.create!(
          client: client, company: company, created_by: created_by,
          amount: amount, currency: currency, payment_method: payment_method, notes: notes,
          status: :paid, paid_at: Time.current,
          membership: membership, booking: booking
        )

        update_payable_status!
      end

      Result.new(success?: true, payment: payment, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, payment: nil, error: e.record.errors.full_messages.first)
    end

    private

    attr_reader :client, :company, :created_by, :amount, :payment_method, :currency, :notes, :membership, :booking

    # A record's payment_status reflects total paid vs. what it owes — this
    # payment is one more contribution toward that total, not necessarily the
    # only one (partial payments accumulate).
    def update_payable_status!
      if membership
        total_paid = membership.payments.reload.paid.sum(:amount)
        membership.update!(payment_status: total_paid >= membership.final_price.to_f ? :paid : :partial)
      elsif booking
        total_paid = booking.payments.reload.paid.sum(:amount)
        booking.update!(payment_status: total_paid >= booking.amount.to_f ? :paid : :partial)
      end
    end
  end
end
