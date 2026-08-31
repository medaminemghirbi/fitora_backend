# Marker + reference for the Fitness domain module.
#
# The platform core (Company, User, Role, Permission, StaffMember, Client,
# Location, Subscription, AuditLog, LibraryDocument, the HR/payroll suite) is
# domain-agnostic. Everything below is fitness-specific and only meaningful
# when a company has the "fitness" module enabled (ModuleRegistry / CompanyModule):
#
#   Models       Coach, CoachLocation, Activity, Session, RecurringSchedule,
#                AttendanceRecord, ContractType, Contract, ContractPeriod,
#                Booking, ContractTypeActivity, ContractTypeLocation
#   Controllers  Api::V1::{Activities,Sessions,Bookings,Contracts,ContractTypes,
#                Attendance,RecurringSchedules}Controller — each guarded by
#                BaseController#require_module!(:fitness)
#   Services     Bookings::*, Contracts::*, Sessions::*, Attendance::*,
#                CheckIns::*, RecurringSchedules::*
#
# Table names are deliberately left unprefixed — isolation here is logical
# (this list + the module guards), not physical. A future Medical or Legal
# module slots in alongside without the core needing to know it exists.
module Fitness
  MODULE_KEY = "fitness".freeze

  def self.enabled_for?(company)
    company&.module_enabled?(MODULE_KEY) || false
  end
end
