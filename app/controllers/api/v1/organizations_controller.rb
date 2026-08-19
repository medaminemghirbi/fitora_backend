module Api
  module V1
    class OrganizationsController < BaseController
      before_action :require_owner!

      # GET /api/v1/organization
      def show
        render json: { organization: OrganizationSerializer.new(current_organization).as_json }
      end

      # POST /api/v1/organization
      def create
        if current_organization.present?
          return render json: { error: "You already have an organization" }, status: :unprocessable_entity
        end

        organization = Organization.new(organization_params)
        organization.owner = current_user

        ActiveRecord::Base.transaction do
          organization.save!
          # Full access, not the entry-level paid plan — see the free_trial
          # plan's own comment in db/seeds.rb for why it's a distinct plan
          # rather than just an unpaid stint on "basic". Subscription#locked?
          # flips on once expires_at passes, unless a platform admin
          # upgrades them to a real plan first (which clears it). See
          # Api::V1::BaseController#enforce_trial_lock!.
          trial_plan = SubscriptionPlan.find_by!(code: "free_trial")
          organization.create_subscription!(
            subscription_plan: trial_plan,
            status: :active,
            starts_at: Time.current,
            expires_at: 14.days.from_now
          )

          # One location per organization, always — created here so the
          # owner never has to think about "locations" as a separate setup
          # step before they can add activities or staff.
          organization.locations.create!(
            name: organization.name,
            address: organization.address,
            phone: organization.phone,
            email: organization.email,
            city: organization.city,
            timezone: organization.timezone
          )
        end

        render json: { organization: OrganizationSerializer.new(organization).as_json }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first, errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/organization
      def update
        require_organization!
        return if performed?

        if current_organization.update(organization_params)
          render json: { organization: OrganizationSerializer.new(current_organization).as_json }
        else
          render json: { error: current_organization.errors.full_messages.first, errors: current_organization.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def organization_params
        params.require(:organization).permit(
          :name, :description, :phone, :email, :country, :city,
          :address, :latitude, :longitude, :timezone, :currency
        )
      end
    end
  end
end
