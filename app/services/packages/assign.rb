module Packages
  class Assign
    Result = Struct.new(:success?, :client_package, :payment, :error, keyword_init: true)

    def self.call(client:, package:, created_by:, payment_method: nil, payment_amount: nil, payment_notes: nil)
      new(client: client, package: package, created_by: created_by,
          payment_method: payment_method, payment_amount: payment_amount, payment_notes: payment_notes).call
    end

    def initialize(client:, package:, created_by:, payment_method:, payment_amount:, payment_notes:)
      @client = client
      @package = package
      @created_by = created_by
      @payment_method = payment_method
      @payment_amount = payment_amount
      @payment_notes = payment_notes
    end

    def call
      client_package = nil
      payment = nil

      ActiveRecord::Base.transaction do
        purchased_at = Time.current

        client_package = ClientPackage.create!(
          client: client,
          package: package,
          status: :active,
          purchased_at: purchased_at,
          expires_at: purchased_at + package.validity_days.days,
          remaining_credits: package.credits
        )

        if payment_amount.present? && payment_amount.to_f > 0
          payment = Payment.create!(
            client: client, organization: package.organization, created_by: created_by, client_package: client_package,
            amount: payment_amount, currency: package.currency, payment_method: payment_method.presence || :cash,
            status: :paid, paid_at: Time.current, notes: payment_notes
          )
        end
      end

      Result.new(success?: true, client_package: client_package, payment: payment, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, client_package: nil, payment: nil, error: e.record.errors.full_messages.first)
    end

    private

    attr_reader :client, :package, :created_by, :payment_method, :payment_amount, :payment_notes
  end
end
