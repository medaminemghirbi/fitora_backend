module Api
  module V1
    class SubscriptionController < BaseController
      before_action :require_owner!, only: [ :show, :request_upgrade ]

      # GET /api/v1/subscription
      def show
        subscription = current_organization&.subscription

        render json: {
          subscription: SubscriptionSerializer.new(subscription).as_json,
          locations_used: current_organization&.locations&.count || 0,
          clients_used: current_organization&.clients&.count || 0,
          staff_used: current_organization&.staff_members&.count || 0,
          locked: subscription&.locked? || false,
          trial_days_remaining: subscription&.days_remaining
        }
      end

      # GET /api/v1/subscription/plans
      def plans
        render json: { plans: SubscriptionPlan.active.order(:price).map { |p| SubscriptionPlanSerializer.new(p).as_json } }
      end

      # POST /api/v1/subscription/upgrade-request — no self-service billing
      # yet, so this only records what the owner picked (plan + how they say
      # they'll pay); a platform admin still applies the actual plan change
      # by hand via Admin::OrganizationsController#update_subscription once
      # they've verified payment, same as any other manual upgrade today.
      def request_upgrade
        plan = SubscriptionPlan.active.find_by(id: params[:plan_id])
        return render json: { error: "Subscription plan not found" }, status: :not_found if plan.nil?

        unless SubscriptionUpgradeRequest.payment_methods.key?(params[:payment_method])
          return render json: { error: "Invalid payment method" }, status: :unprocessable_entity
        end

        upgrade_request = SubscriptionUpgradeRequest.new(
          organization: current_organization,
          subscription_plan: plan,
          requested_by: current_user,
          payment_method: params[:payment_method]
        )

        if upgrade_request.save
          AuditLogs::Record.call(
            organization: current_organization, user: current_user, action: "subscription.upgrade_requested",
            auditable: upgrade_request, metadata: { plan: plan.name, payment_method: upgrade_request.payment_method }
          )
          render json: { status: upgrade_request.status }, status: :created
        else
          render json: { error: upgrade_request.errors.full_messages.first, errors: upgrade_request.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
