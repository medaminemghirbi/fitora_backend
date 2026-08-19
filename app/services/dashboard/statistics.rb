module Dashboard
  class Statistics
    def self.call(company:)
      new(company: company).call
    end

    def initialize(company:)
      @company = company
    end

    def call
      {
        total_clients: company.clients.active.count,
        active_memberships: company.memberships.currently_active.count,
        todays_bookings: todays_bookings.count,
        todays_attendance: todays_attendance_count,
        outstanding_payments: outstanding_payments_total,
        todays_schedule: todays_schedule,
        memberships_expiring: memberships_expiring,
        recent_payments: recent_payments,
        recent_clients: recent_clients
      }
    end

    private

    attr_reader :company

    def base_sessions_scope
      Session.joins(:location).where(locations: { company_id: company.id })
    end

    def todays_bookings
      Booking.confirmed.joins(:session).merge(base_sessions_scope).where(sessions: { starts_at: Time.current.all_day })
    end

    def todays_attendance_count
      AttendanceRecord.present.joins(booking: :session).merge(base_sessions_scope)
                       .where(sessions: { starts_at: Time.current.all_day }).count
    end

    def outstanding_payments_total
      unpaid_bookings = Booking.joins(:session).merge(base_sessions_scope)
                                .where(payment_status: %i[unpaid partial]).sum(:amount)
      unpaid_memberships = company.memberships.where(payment_status: %i[unpaid partial]).sum(:final_price)
      unpaid_bookings + unpaid_memberships
    end

    def todays_schedule
      base_sessions_scope
        .where(starts_at: Time.current.all_day)
        .order(:starts_at)
        .includes(:activity, :coach, :location)
        .map do |session|
          {
            id: session.id,
            starts_at: session.starts_at,
            activity_name: session.activity.name,
            activity_emoji: session.activity.emoji,
            coach_name: session.coach&.full_name,
            location_name: session.location.name,
            confirmed_count: session.confirmed_bookings_count,
            capacity: session.capacity,
            status: session.status
          }
        end
    end

    def memberships_expiring
      company.memberships.expiring_soon.includes(:client, :membership_plan).order(:expires_at).limit(5).map do |m|
        { id: m.id, client_name: m.client.full_name, plan_name: m.membership_plan.name, expires_at: m.expires_at }
      end
    end

    def recent_payments
      company.payments.paid.recent.includes(:client).limit(5).map do |p|
        { id: p.id, client_name: p.client.full_name, amount: p.amount, currency: p.currency, paid_at: p.paid_at }
      end
    end

    def recent_clients
      company.clients.order(created_at: :desc).limit(5).map do |c|
        { id: c.id, full_name: c.full_name, joined_at: c.joined_at }
      end
    end
  end
end
