module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_request!
      before_action :enforce_trial_lock!

      private

      # The only endpoints a locked organization's owner can still reach —
      # enough to see their plan status and what it costs to upgrade, and
      # nothing that operates the gym. Staff get no exceptions at all: once
      # the free trial (or a fixed-term paid period) expires, only the owner
      # has any access, and only to this much.
      OWNER_ALLOWED_WHEN_LOCKED = {
        "Api::V1::SubscriptionController" => %w[show plans],
        "Api::V1::OrganizationsController" => %w[show]
      }.freeze
      private_constant :OWNER_ALLOWED_WHEN_LOCKED

      def enforce_trial_lock!
        return if current_user.admin?

        subscription = current_organization&.subscription
        return unless subscription&.locked?

        return if current_user.owner? && OWNER_ALLOWED_WHEN_LOCKED[self.class.name]&.include?(action_name)

        render json: {
          error: "trial_expired",
          message: current_user.owner? ? "Your free trial has ended. Upgrade your plan to keep using Fitora." : "This organization's account is locked. Contact your gym owner."
        }, status: :payment_required
      end

      # Never trust an organization_id supplied by the client — always derive
      # it from the authenticated user: owners have one via Organization,
      # staff (managers/coaches/receptionists/org-admins) have one via
      # StaffMember. Never confuse either with User#role == "admin", the
      # Fitora platform operator handled entirely by Api::V1::Admin::*.
      def current_organization
        @current_organization ||= current_user.organization || current_staff_member&.organization
      end

      def current_staff_member
        return nil unless current_user.staff?

        @current_staff_member ||= current_user.staff_member
      end

      def require_owner!
        render_forbidden unless current_user.owner?
      end

      def require_admin!
        render_forbidden unless current_user.admin?
      end

      # True for the owner (always) or for staff whose role grants this
      # capability (StaffMember::CAPABILITIES) — the only two ways into any
      # endpoint gated by this check.
      def require_capability!(capability)
        return if current_user.owner?
        return if current_staff_member&.active? && current_staff_member.can?(capability)

        render_forbidden
      end

      # Anyone with a seat in the org can see the calendar — the schedule is
      # shared operational context for every role. Editing sessions is a
      # separate, narrower check (require_capability!(:sessions)).
      def require_staff!
        return if current_user.owner?
        return if current_staff_member&.active?

        render_forbidden
      end

      def require_organization!
        render json: { error: "No organization found for this account" }, status: :unprocessable_entity if current_organization.nil?
      end

      def paginate(scope)
        page = [ params[:page].to_i, 1 ].max
        per_page = params[:per_page].to_i
        per_page = 20 if per_page <= 0
        per_page = [ per_page, 100 ].min

        scope.limit(per_page).offset((page - 1) * per_page)
      end

      def pagination_meta(scope)
        page = [ params[:page].to_i, 1 ].max
        per_page = params[:per_page].to_i
        per_page = 20 if per_page <= 0
        per_page = [ per_page, 100 ].min
        total = scope.count

        { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
      end
    end
  end
end
