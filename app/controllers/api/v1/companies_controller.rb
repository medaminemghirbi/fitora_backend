module Api
  module V1
    class CompaniesController < BaseController
      before_action :require_owner!

      # GET /api/v1/company
      def show
        render json: { company: CompanySerializer.new(current_company).as_json }
      end

      # POST /api/v1/company
      def create
        if current_company.present?
          return render json: { error: "You already have a company" }, status: :unprocessable_entity
        end

        company = Company.new(company_params)
        company.owner = current_user

        ActiveRecord::Base.transaction do
          company.save!
          # Full access, not the entry-level paid plan — see the free_trial
          # plan's own comment in db/seeds.rb for why it's a distinct plan
          # rather than just an unpaid stint on "basic". Contract#locked?
          # flips on once expires_at passes, unless a platform admin
          # upgrades them to a real plan first (which clears it). See
          # Api::V1::BaseController#enforce_trial_lock!.
          trial_plan = ContractPlan.find_by!(code: "free_trial")
          company.create_contract!(
            contract_plan: trial_plan,
            status: :active,
            starts_at: Time.current,
            expires_at: 14.days.from_now
          )

          # One location per company, always — created here so the
          # owner never has to think about "locations" as a separate setup
          # step before they can add activities or staff.
          company.locations.create!(
            name: company.name,
            address: company.address,
            phone: company.phone,
            email: company.email,
            city: company.city,
            timezone: company.timezone
          )
        end

        render json: { company: CompanySerializer.new(company).as_json }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first, errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/company
      def update
        require_company!
        return if performed?

        if current_company.update(company_params)
          render json: { company: CompanySerializer.new(current_company).as_json }
        else
          render json: { error: current_company.errors.full_messages.first, errors: current_company.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def company_params
        params.require(:company).permit(
          :name, :description, :phone, :email, :country, :city,
          :address, :latitude, :longitude, :timezone, :currency
        )
      end
    end
  end
end
