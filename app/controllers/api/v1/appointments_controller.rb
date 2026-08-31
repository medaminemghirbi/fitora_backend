module Api
  module V1
    class AppointmentsController < BaseController
      before_action -> { require_module!(:appointments) }
      before_action :require_company!
      before_action -> { require_capability!(:appointments) }
      before_action :set_appointment, only: [ :show, :update, :destroy, :cancel ]

      # GET /api/v1/appointments?from=&to=&staff_member_id=
      def index
        scope = current_company.appointments
                               .includes(:client, :appointment_type, staff_member: :user)
                               .chronological

        if params[:from].present? && params[:to].present?
          scope = scope.in_range(Time.zone.parse(params[:from]), Time.zone.parse(params[:to]))
        end
        scope = scope.where(staff_member_id: params[:staff_member_id]) if params[:staff_member_id].present?

        render json: { appointments: scope.map { |a| AppointmentSerializer.new(a).as_json } }
      end

      # GET /api/v1/appointments/:id
      def show
        render json: { appointment: AppointmentSerializer.new(@appointment).as_json }
      end

      # POST /api/v1/appointments
      def create
        appointment = current_company.appointments.new(appointment_params)
        appointment.created_by = current_user

        if appointment.save
          AuditLogs::Record.call(company: current_company, user: current_user, action: "appointment.created", auditable: appointment)
          render json: { appointment: AppointmentSerializer.new(appointment).as_json }, status: :created
        else
          render_error(appointment)
        end
      end

      # PATCH /api/v1/appointments/:id
      def update
        if @appointment.update(appointment_params)
          render json: { appointment: AppointmentSerializer.new(@appointment.reload).as_json }
        else
          render_error(@appointment)
        end
      end

      # POST /api/v1/appointments/:id/cancel
      def cancel
        @appointment.update!(status: :cancelled)
        render json: { appointment: AppointmentSerializer.new(@appointment).as_json }
      end

      # DELETE /api/v1/appointments/:id
      def destroy
        @appointment.destroy!
        head :no_content
      end

      private

      def set_appointment
        @appointment = current_company.appointments.find(params[:id])
      end

      def appointment_params
        params.require(:appointment).permit(
          :client_id, :staff_member_id, :appointment_type_id, :location_id,
          :starts_at, :ends_at, :status, :title, :notes
        )
      end

      def render_error(record)
        render json: { error: record.errors.full_messages.first, errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
