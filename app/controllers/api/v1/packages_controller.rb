module Api
  module V1
    class PackagesController < BaseController
      before_action :require_organization!
      before_action -> { require_capability!(:memberships) }
      before_action :set_package, only: [ :show, :update ]

      # GET /api/v1/packages
      def index
        render json: { packages: current_organization.packages.order(:name).map { |p| PackageSerializer.new(p).as_json } }
      end

      # GET /api/v1/packages/:id
      def show
        render json: { package: PackageSerializer.new(@package).as_json }
      end

      # POST /api/v1/packages
      def create
        package = current_organization.packages.new(package_params)

        if package.save
          render json: { package: PackageSerializer.new(package).as_json }, status: :created
        else
          render json: { error: package.errors.full_messages.first, errors: package.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/packages/:id
      def update
        if @package.update(package_params)
          render json: { package: PackageSerializer.new(@package).as_json }
        else
          render json: { error: @package.errors.full_messages.first, errors: @package.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/packages/:id/assign — staff assigns this package to a client
      def assign
        set_package
        client = current_organization.clients.find_by(id: params[:client_id])
        return render json: { error: "Client not found" }, status: :not_found if client.nil?

        result = Packages::Assign.call(
          client: client, package: @package, created_by: current_user,
          payment_method: params[:payment_method], payment_amount: params[:payment_amount], payment_notes: params[:payment_notes]
        )

        if result.success?
          render json: {
            client_package: ClientPackageSerializer.new(result.client_package).as_json,
            payment: PaymentSerializer.new(result.payment).as_json
          }, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def set_package
        @package = current_organization.packages.find(params[:id])
      end

      def package_params
        params.require(:package).permit(:activity_id, :name, :description, :price, :currency, :credits, :validity_days, :active)
      end
    end
  end
end
