module Bookings
  class Create
    Result = Struct.new(:success?, :booking, :error, keyword_init: true)

    def self.call(client:, session:)
      new(client: client, session: session).call
    end

    def initialize(client:, session:)
      @client = client
      @session = session
    end

    def call
      booking = nil
      error = nil

      ActiveRecord::Base.transaction do
        locked_session = Session.lock.find(session.id)
        activity = locked_session.activity
        organization = activity.location.organization

        if locked_session.cancelled?
          error = "This session has been cancelled."
        elsif locked_session.starts_at < Time.current
          error = "This session is no longer available."
        elsif locked_session.bookings.held.where(client_id: client.id).exists?
          error = "This client already has a booking for this session."
        elsif locked_session.held_bookings_count >= locked_session.capacity
          error = "This session is full."
        elsif activity.free?
          booking = confirm_free(locked_session)
        else
          coverage = find_coverage(organization: organization, location: locked_session.location, activity: activity)

          if coverage
            booking = confirm_with_coverage(locked_session, coverage)
          elsif activity.membership_required?
            error = "This client needs an active membership to book this activity."
          else
            booking = confirm_unpaid(locked_session, organization)
          end
        end

        raise ActiveRecord::Rollback if error
      end

      if error
        Result.new(success?: false, booking: nil, error: error)
      else
        Result.new(success?: true, booking: booking, error: nil)
      end
    rescue ActiveRecord::RecordNotUnique
      Result.new(success?: false, booking: nil, error: "This client already has a booking for this session.")
    end

    private

    attr_reader :client, :session

    Coverage = Struct.new(:kind, :record)

    def find_coverage(organization:, location:, activity:)
      membership = client.memberships.currently_active
                          .where(organization: organization)
                          .find { |m| m.usable_for?(location: location, activity: activity) }
      return Coverage.new(:membership, membership) if membership

      return nil if activity.membership_required?

      client_package = client.client_packages.currently_active
                              .joins(:package).where(packages: { organization_id: organization.id })
                              .find { |cp| cp.usable_for?(activity: activity) }
      client_package ? Coverage.new(:package, client_package) : nil
    end

    def confirm_with_coverage(locked_session, coverage)
      booking = locked_session.bookings.create!(
        client: client,
        status: :confirmed,
        amount: 0,
        currency: locked_session.activity.location.organization.currency,
        payment_status: :paid,
        membership: coverage.kind == :membership ? coverage.record : nil,
        client_package: coverage.kind == :package ? coverage.record : nil
      )

      coverage.record.consume_booking! if coverage.kind == :membership
      coverage.record.consume_credit! if coverage.kind == :package

      booking
    end

    def confirm_free(locked_session)
      locked_session.bookings.create!(
        client: client,
        status: :confirmed,
        amount: 0,
        currency: locked_session.activity.location.organization.currency,
        payment_status: :paid
      )
    end

    def confirm_unpaid(locked_session, organization)
      locked_session.bookings.create!(
        client: client,
        status: :confirmed,
        amount: locked_session.price,
        currency: organization.currency,
        payment_status: :unpaid
      )
    end
  end
end
