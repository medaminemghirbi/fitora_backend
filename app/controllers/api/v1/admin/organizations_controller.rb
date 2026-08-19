module Api
  module V1
    module Admin
      class OrganizationsController < BaseController
        before_action :require_admin!
        before_action :set_organization, only: [ :show, :update_subscription, :impersonate ]

        # GET /api/v1/admin/organizations
        def index
          organizations = Organization.includes(:owner, subscription: :subscription_plan).order(:name)

          render json: {
            organizations: paginate(organizations).map { |o| AdminOrganizationSerializer.new(o).as_json },
            meta: pagination_meta(organizations)
          }
        end

        # GET /api/v1/admin/organizations/:id
        def show
          render json: { organization: AdminOrganizationSerializer.new(@organization).as_json }
        end

        # PATCH /api/v1/admin/organizations/:id/subscription
        # Direct admin override — the owner is invoiced/paid outside the app
        # (bank transfer, in person, etc.); this just applies the plan change.
        def update_subscription
          plan = SubscriptionPlan.find_by(id: params[:subscription_plan_id])
          return render json: { error: "Subscription plan not found" }, status: :not_found if plan.nil?

          subscription = @organization.subscription || @organization.build_subscription(starts_at: Time.current)
          previous_plan = subscription.subscription_plan&.name

          if subscription.update(
            subscription_plan: plan,
            status: params[:status] || subscription.status,
            auto_renew: params.fetch(:auto_renew, subscription.auto_renew),
            # An admin assigning a plan is what "upgrading" means in this
            # app (no self-service billing) — clears the free-trial deadline
            # by default so the organization is unlocked. Pass expires_at
            # explicitly to set a new one instead (e.g. a fixed-term deal).
            expires_at: params[:expires_at].presence
          )
            AuditLogs::Record.call(
              organization: @organization, user: current_user, action: "subscription.plan_overridden",
              auditable: subscription, metadata: { from: previous_plan, to: plan.name }
            )
            render json: { organization: AdminOrganizationSerializer.new(@organization.reload).as_json }
          else
            render json: { error: subscription.errors.full_messages.first, errors: subscription.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/admin/organizations/:id/impersonate — issues a real
        # login session for the organization's owner, marked with this
        # admin's id so it's traceable, and reuses the entire owner-facing
        # app as-is instead of duplicating every page for admin use.
        def impersonate
          owner = @organization.owner
          return render json: { error: "This organization has no owner account" }, status: :unprocessable_entity if owner.nil?

          AuditLogs::Record.call(
            organization: @organization, user: owner, action: "admin.impersonation_started",
            auditable: @organization, metadata: { admin_id: current_user.id, admin_email: current_user.email }
          )

          render json: { token: JwtService.encode(owner.id, impersonator_id: current_user.id), user: UserSerializer.new(owner).as_json }
        end

        private

        def set_organization
          @organization = Organization.find(params[:id])
        end
      end
    end
  end
end
