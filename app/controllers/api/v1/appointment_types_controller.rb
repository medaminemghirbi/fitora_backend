module Api
  module V1
    # Appointment categories (name + default duration + colour), managed from
    # Settings. Owner-only, and only when the appointments module is enabled.
    class AppointmentTypesController < BaseController
      before_action -> { require_module!(:appointments) }
      before_action :require_company!
      before_action :require_owner!
      before_action :set_type, only: [ :update, :destroy ]

      def index
        types = current_company.appointment_types.ordered
        render json: { appointment_types: types.map { |t| AppointmentTypeSerializer.new(t).as_json } }
      end

      def create
        type = current_company.appointment_types.new(type_params)

        if type.save
          render json: { appointment_type: AppointmentTypeSerializer.new(type).as_json }, status: :created
        else
          render_error(type)
        end
      end

      def update
        if @type.update(type_params)
          render json: { appointment_type: AppointmentTypeSerializer.new(@type).as_json }
        else
          render_error(@type)
        end
      end

      def destroy
        @type.destroy!
        head :no_content
      end

      private

      def set_type
        @type = current_company.appointment_types.find(params[:id])
      end

      def type_params
        params.require(:appointment_type).permit(:name, :duration_minutes, :color, :active, :position)
      end

      def render_error(record)
        render json: { error: record.errors.full_messages.first, errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
