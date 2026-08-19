class CreateMembershipPlanActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_plan_activities do |t|
      t.references :membership_plan, null: false, foreign_key: true, index: true
      t.references :activity, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :membership_plan_activities, [ :membership_plan_id, :activity_id ], unique: true, name: "index_plan_activities_unique"
  end
end
