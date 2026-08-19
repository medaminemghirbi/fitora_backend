module Api
  module V1
    class CoachesController < BaseController
      before_action -> { require_capability!(:coaches) }
      before_action :require_organization!
      before_action :set_coach, only: [ :show, :update, :destroy ]

      # GET /api/v1/coaches
      def index
        render json: { coaches: current_organization.coaches.order(:first_name).map { |c| CoachSerializer.new(c).as_json } }
      end

      # GET /api/v1/coaches/:id
      def show
        render json: { coach: CoachSerializer.new(@coach).as_json }
      end

      # POST /api/v1/coaches — auto-assigned to the organization's one location
      def create
        coach = current_organization.coaches.new(coach_params)

        if coach.save
          coach.coach_locations.create!(location: current_organization.location)
          render json: { coach: CoachSerializer.new(coach.reload).as_json }, status: :created
        else
          render json: { error: coach.errors.full_messages.first, errors: coach.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/coaches/:id
      def update
        if @coach.update(coach_params)
          render json: { coach: CoachSerializer.new(@coach).as_json }
        else
          render json: { error: @coach.errors.full_messages.first, errors: @coach.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/coaches/:id — soft deactivate
      def destroy
        @coach.update!(active: false)
        render json: { coach: CoachSerializer.new(@coach).as_json }
      end

      private

      def set_coach
        @coach = current_organization.coaches.find(params[:id])
      end

      def coach_params
        params.require(:coach).permit(:first_name, :last_name, :email, :phone, :bio, :photo_url, :active)
      end
    end
  end
end
