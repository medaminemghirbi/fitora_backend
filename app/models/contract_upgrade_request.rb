class ContractUpgradeRequest < ApplicationRecord
  belongs_to :company
  belongs_to :contract_plan
  belongs_to :requested_by, class_name: "User"

  enum :payment_method, { cash: 0, card: 1, bank_transfer: 2 }
  enum :status, { pending: 0, approved: 1, rejected: 2 }
end
