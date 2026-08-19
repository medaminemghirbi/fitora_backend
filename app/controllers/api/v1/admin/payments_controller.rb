module Api
  module V1
    module Admin
      class PaymentsController < BaseController
        before_action :require_admin!

        # GET /api/v1/admin/payments?organization_id=&status=&date=
        def index
          scope = Payment.includes(:client, :organization)
          scope = scope.where(organization_id: params[:organization_id]) if params[:organization_id].present?
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where("payments.created_at >= ?", Date.parse(params[:date]).beginning_of_day) if params[:date].present?
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
