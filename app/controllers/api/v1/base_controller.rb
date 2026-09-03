module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_request!
      before_action :enforce_trial_lock!

      private

      # The only endpoints a locked company's owner can still reach — enough
      # to see their status, and nothing that operates the gym. Staff get no
      # exceptions at all: once the free trial expires, only the owner has
      # any access, and only to this much, until a platform admin manually
      # grants access again (Api::V1::Admin::CompaniesController#update_subscription).
      OWNER_ALLOWED_WHEN_LOCKED = {
        "Api::V1::SubscriptionController" => %w[show],
        "Api::V1::CompaniesController" => %w[show]
      }.freeze
      private_constant :OWNER_ALLOWED_WHEN_LOCKED

      def enforce_trial_lock!
        return if current_user.admin?

        subscription = current_company&.subscription
        return unless subscription&.locked?

        return if current_user.owner? && OWNER_ALLOWED_WHEN_LOCKED[self.class.name]&.include?(action_name)

        render json: {
          error: "trial_expired",
          message: current_user.owner? ? "Your free trial has ended. Contact Gerily to keep using your account." : "This company's account is locked. Contact your gym owner."
        }, status: :payment_required
      end

      # Never trust a company_id supplied by the client — always derive
      # it from the authenticated user: owners have one via Company,
      # staff (managers/coaches/receptionists/company-admins) have one via
      # StaffMember. Never confuse either with User#role == "admin", the
      # Gerily platform operator handled entirely by Api::V1::Admin::*.
      def current_company
        @current_company ||= current_user.company || current_staff_member&.company
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
      # capability — the only two ways into any endpoint gated by this check.
      def require_capability!(capability)
        return if current_user.owner?
        return if current_staff_member&.active? && current_staff_member.can?(capability)

        render_forbidden
      end

      # Guards a domain module's endpoints — the API-side equivalent of the
      # frontend moduleGuard. A company that hasn't enabled the module can't
      # reach its resources even by calling the API directly.
      def require_module!(key)
        return if current_company&.module_enabled?(key)

        render json: { error: "module_not_enabled", message: "This feature is not enabled for your company." }, status: :forbidden
      end

      # Anyone with a seat in the company can see the calendar — the schedule is
      # shared operational context for every role. Editing sessions is a
      # separate, narrower check (require_capability!(:sessions)).
      def require_staff!
        return if current_user.owner?
        return if current_staff_member&.active?

        render_forbidden
      end

      def require_company!
        render json: { error: "No company found for this account" }, status: :unprocessable_entity if current_company.nil?
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
