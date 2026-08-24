module Api
  module V1
    # No plans, no add-ons — a company's access to Fitora is granted and
    # managed entirely by hand by a platform admin
    # (Api::V1::Admin::CompaniesController#update_subscription). This just
    # reports the current status/trial countdown for the owner's own banner
    # and the trial-expired page.
    class SubscriptionController < BaseController
      before_action :require_owner!

      # GET /api/v1/subscription
      def show
        subscription = current_company&.subscription

        render json: {
          subscription: SubscriptionSerializer.new(subscription).as_json,
          locations_used: current_company&.locations&.count || 0,
          clients_used: current_company&.clients&.count || 0,
          staff_used: current_company&.staff_members&.count || 0,
          locked: subscription&.locked? || false,
          trial_days_remaining: subscription&.days_remaining
        }
      end
    end
  end
end
