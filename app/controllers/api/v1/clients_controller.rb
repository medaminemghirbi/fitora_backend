module Api
  module V1
    class ClientsController < BaseController
      before_action :require_organization!
      before_action -> { require_capability!(:clients) }
      before_action :set_client, only: [ :show, :update ]

      # GET /api/v1/clients?search=&status=&page=
      # status: active | inactive | membership_active | membership_expired | no_membership
      def index
        clients = filtered_scope.order(:first_name, :last_name)

        if params[:format] == "csv"
          send_data clients_csv(clients), filename: "clients-#{Date.current}.csv"
        else
          render json: {
            clients: paginate(clients).map { |c| ClientSerializer.new(c).as_json },
            meta: pagination_meta(clients)
          }
        end
      end

      # GET /api/v1/clients/:id
      def show
        render json: {
          client: ClientSerializer.new(@client, detailed: true).as_json,
          memberships: @client.memberships.includes(:membership_plan).order(created_at: :desc).map { |m| MembershipSerializer.new(m).as_json },
          bookings: @client.bookings.includes(session: [ :activity, :location, :coach ]).order(created_at: :desc).limit(20).map { |b| BookingSerializer.new(b).as_json },
          payments: @client.payments.recent.limit(20).map { |p| PaymentSerializer.new(p).as_json },
          client_packages: @client.client_packages.includes(:package).order(created_at: :desc).map { |cp| ClientPackageSerializer.new(cp).as_json }
        }
      end

      # POST /api/v1/clients
      def create
        client = current_organization.clients.new(client_params)

        if client.save
          render json: { client: ClientSerializer.new(client).as_json }, status: :created
        else
          render json: { error: client.errors.full_messages.first, errors: client.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/clients/:id
      def update
        if @client.update(client_params)
          render json: { client: ClientSerializer.new(@client).as_json }
        else
          render json: { error: @client.errors.full_messages.first, errors: @client.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_client
        @client = current_organization.clients.find(params[:id])
      end

      def filtered_scope
        scope = current_organization.clients.search(params[:search])

        case params[:status]
        when "active" then scope.active
        when "inactive" then scope.where(active: false)
        when "membership_active" then scope.joins(:memberships).merge(Membership.currently_active).distinct
        when "membership_expired" then scope.joins(:memberships).merge(Membership.where(status: :expired)).distinct
        when "no_membership" then scope.where.missing(:memberships)
        else scope
        end
      end

      def clients_csv(clients)
        CSV.generate do |csv|
          csv << [ "First name", "Last name", "Email", "Phone", "Active", "Joined at" ]
          clients.find_each do |c|
            csv << [ c.first_name, c.last_name, c.email, c.phone, c.active, c.joined_at ]
          end
        end
      end

      def client_params
        params.require(:client).permit(
          :first_name, :last_name, :email, :phone, :date_of_birth, :gender,
          :address, :emergency_contact_name, :emergency_contact_phone, :notes, :active
        )
      end
    end
  end
end
