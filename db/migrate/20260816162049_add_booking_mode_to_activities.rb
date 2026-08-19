class AddBookingModeToActivities < ActiveRecord::Migration[8.0]
  def change
    # 0 = free, 1 = pay_per_booking, 2 = membership_required. Defaulting to
    # free preserves V0 behavior for every existing activity (instant booking,
    # no payment gate) until an owner opts an activity into monetization.
    add_column :activities, :booking_mode, :integer, null: false, default: 0
  end
end
