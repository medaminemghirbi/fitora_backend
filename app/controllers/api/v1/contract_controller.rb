module Api
  module V1
    class ContractController < BaseController
      before_action :require_owner!, only: [ :show, :request_upgrade ]

      # GET /api/v1/contract
      def show
        contract = current_company&.contract

        render json: {
          contract: ContractSerializer.new(contract).as_json,
          locations_used: current_company&.locations&.count || 0,
          clients_used: current_company&.clients&.count || 0,
          staff_used: current_company&.staff_members&.count || 0,
          locked: contract&.locked? || false,
          trial_days_remaining: contract&.days_remaining
        }
      end

      # GET /api/v1/contract/plans
      def plans
        render json: { plans: ContractPlan.active.order(:price).map { |p| ContractPlanSerializer.new(p).as_json } }
      end

      # POST /api/v1/contract/upgrade-request — no self-service billing
      # yet, so this only records what the owner picked (plan + how they say
      # they'll pay); a platform admin still applies the actual plan change
      # by hand via Admin::CompaniesController#update_contract once
      # they've verified payment, same as any other manual upgrade today.
      def request_upgrade
        plan = ContractPlan.active.find_by(id: params[:plan_id])
        return render json: { error: "Contract plan not found" }, status: :not_found if plan.nil?

        unless ContractUpgradeRequest.payment_methods.key?(params[:payment_method])
          return render json: { error: "Invalid payment method" }, status: :unprocessable_entity
        end

        upgrade_request = ContractUpgradeRequest.new(
          company: current_company,
          contract_plan: plan,
          requested_by: current_user,
          payment_method: params[:payment_method]
        )

        if upgrade_request.save
          AuditLogs::Record.call(
            company: current_company, user: current_user, action: "contract.upgrade_requested",
            auditable: upgrade_request, metadata: { plan: plan.name, payment_method: upgrade_request.payment_method }
          )
          render json: { status: upgrade_request.status }, status: :created
        else
          render json: { error: upgrade_request.errors.full_messages.first, errors: upgrade_request.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
