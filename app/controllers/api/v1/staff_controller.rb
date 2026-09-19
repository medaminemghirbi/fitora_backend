module Api
  module V1
    class StaffController < BaseController
      before_action :require_organization!
      before_action :require_staff_manager!
      before_action :set_staff_member, only: [ :update ]
      before_action :enforce_staff_limit!, only: [ :create ]

      # GET /api/v1/staff
      def index
        staff = current_organization.staff_members.includes(:user, :coach).order(:role)
        render json: { staff: staff.map { |s| StaffMemberSerializer.new(s).as_json } }
      end

      # POST /api/v1/staff — auto-assigned to the organization's one location
      def create
        user = User.new(user_params.merge(role: :staff, locale: user_params[:locale].presence || "fr"))
        staff_member = nil

        ActiveRecord::Base.transaction do
          user.save!
          staff_member = current_organization.staff_members.create!(
            user: user,
            role: staff_params[:role],
            coach_id: staff_params[:coach_id]
          )
          staff_member.staff_member_locations.create!(location: current_organization.location)
        end

        AuditLogs::Record.call(
          organization: current_organization, user: current_user, action: "staff.created",
          auditable: staff_member, metadata: { role: staff_member.role, staff_email: user.email }
        )

        render json: { staff_member: StaffMemberSerializer.new(staff_member).as_json }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first, errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/staff/:id
      def update
        previous_role = @staff_member.role

        if @staff_member.update(staff_params)
          if previous_role != @staff_member.role
            AuditLogs::Record.call(
              organization: current_organization, user: current_user, action: "staff.role_changed",
              auditable: @staff_member, metadata: { from: previous_role, to: @staff_member.role }
            )
          end

          render json: { staff_member: StaffMemberSerializer.new(@staff_member.reload).as_json }
        else
          render json: { error: @staff_member.errors.full_messages.first, errors: @staff_member.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Staff management is owner-only now — no in-org staff role has full
      # access anymore, so there's no "staff-admin" exception to make here.
      def require_staff_manager!
        render_forbidden unless current_user.owner?
      end

      def enforce_staff_limit!
        plan = current_organization.current_plan
        return if plan.nil? || !plan.staff_limit_reached?(current_organization.staff_members.count)

        render json: {
          error: "plan_limit_reached", limit_type: "staff", limit: plan.max_staff,
          message: "Your plan allows up to #{plan.max_staff} team members. Upgrade to add more."
        }, status: :unprocessable_entity
      end

      def set_staff_member
        @staff_member = current_organization.staff_members.find(params[:id])
      end

      def user_params
        params.require(:staff_member).permit(:first_name, :last_name, :email, :phone, :password, :locale)
      end

      def staff_params
        params.require(:staff_member).permit(:role, :active, :coach_id)
      end
    end
  end
end
