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

          # Built-in roles (owner/manager/receptionist/coach) — a company can
          # rename them, re-permission them, or add its own from Settings.
          Role.seed_defaults_for(company)

          # Enable the default module set (core + fitness). A later onboarding
          # step can let the company choose a different mix.
          CompanyModule.sync_defaults_for(company)
          # 14-day free trial, full access, no plan to pick. Subscription#locked?
          # flips on once expires_at passes, unless a platform admin grants
          # ongoing access first (which clears it). See
          # Api::V1::BaseController#enforce_trial_lock!.
          company.create_subscription!(
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

          # Standard employment-contract + absence types (CDI/CDD/SIVP…,
          # Congé payé/maladie…) for the RH section — the owner can
          # rename/disable/add their own from Settings.
          WorkContractType.seed_defaults_for(company)
          AbsenceType.seed_defaults_for(company)
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

      # PATCH /api/v1/company/modules — enable/disable optional capability
      # modules. { modules: { "fitness": false } }. `core` can't be turned off.
      def update_modules
        require_company!
        return if performed?

        requested = params.require(:modules).to_unsafe_h
        requested.each do |key, enabled|
          next unless ModuleRegistry::OPTIONAL_KEYS.include?(key.to_s)

          record = current_company.company_modules.find_or_initialize_by(key: key.to_s)
          record.update!(enabled: ActiveModel::Type::Boolean.new.cast(enabled))
        end

        AuditLogs::Record.call(company: current_company, user: current_user, action: "modules.updated", auditable: current_company, metadata: { modules: current_company.reload.enabled_module_keys })
        render json: { modules: current_company.enabled_module_keys }
      end

      # POST /api/v1/company/regenerate_mobile_key — the owner can only
      # roll a fresh random key, never set one by hand (that's admin-only,
      # see Api::V1::Admin::CompaniesController#update_mobile_key).
      def regenerate_mobile_key
        require_company!
        return if performed?

        current_company.regenerate_mobile_auth_key!
        AuditLogs::Record.call(company: current_company, user: current_user, action: "mobile_key.regenerated", auditable: current_company)
        render json: { company: CompanySerializer.new(current_company).as_json }
      end

      # GET /api/v1/company/mobile_key_qr — SVG, generated fresh each call
      # (a handful of characters is cheap to re-encode; not worth caching).
      def mobile_key_qr
        require_company!
        return if performed?

        qr = RQRCode::QRCode.new(current_company.mobile_auth_key)
        svg = qr.as_svg(offset: 8, color: "000", fill: "fff", module_size: 8, use_path: true)

        send_data svg, type: "image/svg+xml", disposition: "inline"
      end

      private

      def company_params
        permitted = params.require(:company).permit(
          :name, :description, :phone, :email, :country, :city,
          :address, :latitude, :longitude, :timezone, :currency,
          :slug, :primary_color, :logo,
          working_days: []
        )
        permitted[:nav_labels] = nav_labels_param if params[:company].key?(:nav_labels)
        permitted
      end

      # nav_labels is an open-ended {labelKey => custom label} map, so it's
      # sanitised by hand rather than through strong-params: string keys and
      # values only, blanks dropped (a blank means "revert to the default").
      def nav_labels_param
        raw = params[:company][:nav_labels]
        return {} unless raw.respond_to?(:each_pair)

        raw.each_pair.filter_map { |key, value|
          label = value.to_s.strip
          [ key.to_s, label ] if label.present?
        }.to_h
      end
    end
  end
end
