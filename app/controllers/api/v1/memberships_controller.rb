module Api
  module V1
    class MembershipsController < BaseController
      before_action :require_organization!
      before_action -> { require_capability!(:memberships) }
      before_action :set_membership, only: [ :show, :renew, :receipt ]
      before_action :require_premium!, only: [ :receipt ]

      # GET /api/v1/memberships — the org's memberships (filterable by status)
      def index
        memberships = current_organization.memberships.includes(:membership_plan, :client).order(created_at: :desc)
        memberships = memberships.where(status: params[:status]) if params[:status].present?

        render json: {
          memberships: paginate(memberships).map { |m| MembershipSerializer.new(m).as_json },
          meta: pagination_meta(memberships)
        }
      end

      # GET /api/v1/memberships/:id
      def show
        render json: { membership: MembershipSerializer.new(@membership).as_json }
      end

      # POST /api/v1/memberships — staff gives a client a membership
      def create
        client = current_organization.clients.find_by(id: params[:client_id])
        return render json: { error: "Client not found" }, status: :not_found if client.nil?

        plan = current_organization.membership_plans.active.find_by(id: params[:membership_plan_id])
        return render json: { error: "Membership plan not found" }, status: :not_found if plan.nil?

        result = Memberships::Create.call(
          client: client, membership_plan: plan, created_by: current_user,
          starts_on: params[:starts_on].present? ? Date.parse(params[:starts_on]) : Date.current,
          discount: params[:discount].presence || 0,
          payment_method: params[:payment_method], payment_amount: params[:payment_amount], payment_notes: params[:payment_notes]
        )

        if result.success?
          render json: {
            membership: MembershipSerializer.new(result.membership).as_json,
            payment: PaymentSerializer.new(result.payment).as_json
          }, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/memberships/:id/renew
      def renew
        result = Memberships::Renew.call(membership: @membership, created_by: current_user)

        if result.success?
          render json: { membership: MembershipSerializer.new(result.membership).as_json }, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/memberships/:id/receipt — Premium+ perk (SubscriptionPlan
      # #premium?, same gate as the owner's Reports::OrganizationWorkbook
      # export). Available to anyone who can already see this membership
      # (require_capability!(:memberships)) — unlike the org-wide export, a
      # single receipt is a day-to-day document a receptionist hands a client
      # right after taking payment, not a business-analytics report.
      def receipt
        pdf_data = Receipts::MembershipPdf.call(membership: @membership)

        send_data pdf_data,
                   filename: "recu-#{@membership.client.full_name.parameterize}-#{@membership.id}.pdf",
                   type: "application/pdf",
                   disposition: "attachment"
      end

      private

      def require_premium!
        plan = current_organization.current_plan
        return if plan&.premium?

        render json: { error: "plan_feature_locked", feature: "advanced_reports" }, status: :forbidden
      end

      def set_membership
        @membership = current_organization.memberships.find(params[:id])
      end
    end
  end
end
