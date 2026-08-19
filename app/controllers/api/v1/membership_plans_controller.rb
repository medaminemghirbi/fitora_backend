module Api
  module V1
    class MembershipPlansController < BaseController
      before_action :require_organization!
      before_action -> { require_capability!(:memberships) }
      before_action :set_plan, only: [ :show, :update ]

      # GET /api/v1/membership_plans
      def index
        plans = current_organization.membership_plans.order(:price)
        render json: { plans: plans.map { |p| MembershipPlanSerializer.new(p).as_json } }
      end

      # GET /api/v1/membership_plans/:id
      def show
        render json: { plan: MembershipPlanSerializer.new(@plan).as_json }
      end

      # POST /api/v1/membership_plans
      def create
        plan = current_organization.membership_plans.new(plan_params)

        if plan.save
          sync_associations(plan)
          render json: { plan: MembershipPlanSerializer.new(plan).as_json }, status: :created
        else
          render json: { error: plan.errors.full_messages.first, errors: plan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/membership_plans/:id
      def update
        if @plan.update(plan_params)
          sync_associations(@plan)
          render json: { plan: MembershipPlanSerializer.new(@plan).as_json }
        else
          render json: { error: @plan.errors.full_messages.first, errors: @plan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_plan
        @plan = current_organization.membership_plans.find(params[:id])
      end

      def sync_associations(plan)
        return unless params[:activity_ids]

        plan.activity_ids = Array(params[:activity_ids]).map(&:to_i) & current_organization.locations.joins(:activities).pluck("activities.id")
      end

      def plan_params
        params.require(:membership_plan).permit(
          :name, :description, :price, :currency, :duration_days,
          :unlimited_bookings, :booking_limit, :priority_booking, :active
        )
      end
    end
  end
end
