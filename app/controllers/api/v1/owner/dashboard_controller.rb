module Api
  module V1
    module Owner
      class DashboardController < BaseController
        before_action -> { require_capability!(:reports) }
        before_action :require_organization!

        # GET /api/v1/owner/dashboard
        def show
          stats = Dashboard::Statistics.call(organization: current_organization)

          render json: {
            organization: OrganizationSerializer.new(current_organization).as_json,
            stats: stats
          }
        end
      end
    end
  end
end
