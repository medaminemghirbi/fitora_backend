class AddRecurringScheduleToSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :sessions, :recurring_schedule, foreign_key: true, index: true
  end
end
