module Api
  module V1
    module Admin
      # Platform-wide catalogue of optional modules and their monthly price.
      # Admin-only. Prices are informational — payment happens outside the app.
      class ModulesController < BaseController
        before_action :require_admin!

        # GET /api/v1/admin/modules
        def index
          rows = PlatformModulePrice.catalog
          counts = CompanyModule.enabled.where(key: rows.map(&:key)).group(:key).count
          render json: {
            modules: rows.map { |row| PlatformModuleSerializer.new(row, companies_count: counts[row.key].to_i).as_json }
          }
        end

        # PATCH /api/v1/admin/modules/:key  { price_cents:, active: }
        def update
          row = PlatformModulePrice.for(params[:key])
          return render(json: { error: "unknown_module" }, status: :not_found) if row.nil?

          attrs = params.permit(:price_cents, :active).to_h
          if row.update(attrs)
            render json: { module: PlatformModuleSerializer.new(row).as_json }
          else
            render json: { error: row.errors.full_messages.first, errors: row.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
