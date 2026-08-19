module Api
  module V1
    class SubscriptionController < BaseController
      before_action :require_owner!, only: [ :show ]

      # GET /api/v1/subscription
      def show
        subscription = current_organization&.subscription

        render json: {
          subscription: SubscriptionSerializer.new(subscription).as_json,
          locations_used: current_organization&.locations&.count || 0,
          locked: subscription&.locked? || false,
          trial_days_remaining: subscription&.days_remaining
        }
      end

      # GET /api/v1/subscription/plans
      def plans
        render json: { plans: SubscriptionPlan.active.order(:price).map { |p| SubscriptionPlanSerializer.new(p).as_json } }
      end
    end
  end
end
