class MarkingPeriodForAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :marking_period, :integer
    create_table :marking_period_grades do |t|
      t.column :student_id, :integer
      t.column :section_id, :integer
      t.column :marking_period, :integer
      t.column :points_earned, :integer
      t.column :points_possible, :integer
    end
  end

  def self.down
    remove_column :assignments, :marking_period
    drop_table :marking_period_grades
  end
end
