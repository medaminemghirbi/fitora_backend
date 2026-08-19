module Api
  module V1
    class MembershipsController < BaseController
      before_action :require_organization!
      before_action -> { require_capability!(:memberships) }
      before_action :set_membership, only: [ :show, :renew ]

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

      private

      def set_membership
        @membership = current_organization.memberships.find(params[:id])
      end
    end
  end
end
