module Api
  module V1
    # Every organization has exactly one location (auto-created at signup,
    # see Api::V1::OrganizationsController#create) — this is a singular
    # resource, same pattern as OrganizationsController, not a full CRUD list.
    class LocationsController < BaseController
      before_action -> { require_capability!(:locations) }
      before_action :require_organization!

      # GET /api/v1/location
      def show
        render json: { location: LocationSerializer.new(current_organization.location).as_json }
      end

      # PATCH /api/v1/location
      def update
        location = current_organization.location

        if location.update(location_params)
          render json: { location: LocationSerializer.new(location).as_json }
        else
          render json: { error: location.errors.full_messages.first, errors: location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def location_params
        params.require(:location).permit(
          :name, :description, :phone, :email, :address, :city,
          :latitude, :longitude, :timezone,
          :business_hours_start, :business_hours_end
        )
      end
    end
  end
end
