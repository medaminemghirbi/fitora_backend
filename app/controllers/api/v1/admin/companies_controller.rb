module Api
  module V1
    module Admin
      class CompaniesController < BaseController
        before_action :require_admin!
        before_action :set_company, only: [ :show, :update_subscription, :impersonate ]

        # GET /api/v1/admin/companies
        def index
          companies = Company.includes(:owner, :subscription).order(:name)

          render json: {
            companies: paginate(companies).map { |o| AdminCompanySerializer.new(o).as_json },
            meta: pagination_meta(companies)
          }
        end

        # GET /api/v1/admin/companies/:id
        def show
          render json: { company: AdminCompanySerializer.new(@company).as_json }
        end

        # PATCH /api/v1/admin/companies/:id/subscription — direct admin
        # override of a company's access status. No plans, no billing: the
        # owner is invoiced/paid outside the app, this just grants or
        # revokes access by hand.
        def update_subscription
          subscription = @company.subscription || @company.build_subscription(starts_at: Time.current)
          previous_status = subscription.status

          if subscription.update(
            status: params[:status] || subscription.status,
            # Granting ongoing access clears the free-trial deadline by
            # default so the company is unlocked. Pass expires_at explicitly
            # to set a new one instead (e.g. a fixed-term arrangement).
            expires_at: params[:expires_at].presence
          )
            AuditLogs::Record.call(
              company: @company, user: current_user, action: "subscription.status_overridden",
              auditable: subscription, metadata: { from: previous_status, to: subscription.status }
            )
            render json: { company: AdminCompanySerializer.new(@company.reload).as_json }
          else
            render json: { error: subscription.errors.full_messages.first, errors: subscription.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/admin/companies/:id/impersonate — issues a real
        # login session for the company's owner, marked with this
        # admin's id so it's traceable, and reuses the entire owner-facing
        # app as-is instead of duplicating every page for admin use.
        def impersonate
          owner = @company.owner
          return render json: { error: "This company has no owner account" }, status: :unprocessable_entity if owner.nil?

          AuditLogs::Record.call(
            company: @company, user: owner, action: "admin.impersonation_started",
            auditable: @company, metadata: { admin_id: current_user.id, admin_email: current_user.email }
          )

          render json: { token: JwtService.encode(owner.id, impersonator_id: current_user.id), user: UserSerializer.new(owner).as_json }
        end

        private

        def set_company
          @company = Company.find(params[:id])
        end
      end
    end
  end
end
