module Api
  module V1
    module Admin
      class PaymentsController < BaseController
        before_action :require_admin!

        # GET /api/v1/admin/payments?company_id=&status=&date=
        def index
          scope = Payment.includes(:client, :company)
          scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where("payments.created_at >= ?", Date.parse(params[:date]).beginning_of_day) if params[:date].present?
          if params[:q].present?
            t = "%#{params[:q].strip}%"
            scope = scope.joins(:client).joins(:company)
              .where("clients.first_name ILIKE :t OR clients.last_name ILIKE :t OR companies.name ILIKE :t", t: t)
          end
          scope = scope.order(created_at: :desc)

          render json: {
            payments: paginate(scope).map { |p| PaymentSerializer.new(p).as_json },
            meta: pagination_meta(scope)
          }
        end
      end
    end
  end
end
