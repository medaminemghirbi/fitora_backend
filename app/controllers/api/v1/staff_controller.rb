module Api
  module V1
    class StaffController < BaseController
      before_action :require_company!
      before_action :require_staff_manager!
      before_action :set_staff_member, only: [ :show, :update ]

      # GET /api/v1/staff
      def index
        staff = current_company.staff_members.includes(:user, :coach).order(:role)
        render json: { staff: staff.map { |s| StaffMemberSerializer.new(s).as_json } }
      end

      # GET /api/v1/staff/:id — the HR "fiche employé" header: identity plus a
      # summary of the current work contract and the paid-leave balance.
      def show
        contract = @staff_member.current_work_contract

        render json: {
          staff_member: StaffMemberSerializer.new(@staff_member).as_json,
          current_work_contract: contract && WorkContractSerializer.new(contract).as_json,
          paid_leave_balance: @staff_member.paid_leave_balance
        }
      end

      # POST /api/v1/staff — auto-assigned to the company's one location
      def create
        user = User.new(user_params.merge(role: :staff, locale: user_params[:locale].presence || "fr"))
        staff_member = nil

        ActiveRecord::Base.transaction do
          user.save!
          staff_member = current_company.staff_members.create!(
            user: user,
            role: staff_params[:role],
            coach_id: staff_params[:coach_id],
            birthdate: staff_params[:birthdate]
          )
          staff_member.staff_member_locations.create!(location: current_company.location)
        end

        AuditLogs::Record.call(
          company: current_company, user: current_user, action: "staff.created",
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
              company: current_company, user: current_user, action: "staff.role_changed",
              auditable: @staff_member, metadata: { from: previous_role, to: @staff_member.role }
            )
          end

          render json: { staff_member: StaffMemberSerializer.new(@staff_member.reload).as_json }
        else
          render json: { error: @staff_member.errors.full_messages.first, errors: @staff_member.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Staff management is owner-only now — no in-company staff role has full
      # access anymore, so there's no "staff-admin" exception to make here.
      def require_staff_manager!
        render_forbidden unless current_user.owner?
      end

      def set_staff_member
        @staff_member = current_company.staff_members.find(params[:id])
      end

      def user_params
        params.require(:staff_member).permit(:first_name, :last_name, :email, :phone, :password, :locale)
      end

      def staff_params
        params.require(:staff_member).permit(:role, :active, :coach_id, :birthdate)
      end
    end
  end
end
