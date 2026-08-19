module Dashboard
  class Revenue
    def self.call(organization:)
      new(organization: organization).call
    end

    def initialize(organization:)
      @organization = organization
    end

    def call
      {
        today: paid_scope.where(paid_at: Time.current.all_day).sum(:amount),
        this_week: paid_scope.where(paid_at: Time.current.all_week).sum(:amount),
        this_month: paid_scope.where(paid_at: Time.current.all_month).sum(:amount),
        by_day: grouped_by_day
      }
    end

    private

    attr_reader :organization

    def paid_scope
      organization.payments.paid
    end

    def grouped_by_day
      paid_scope.where(paid_at: 13.days.ago.beginning_of_day..Time.current)
                .group("DATE(paid_at)")
                .order("DATE(paid_at)")
                .sum(:amount)
                .map { |date, total| { date: date, total: total } }
    end
  end
end
