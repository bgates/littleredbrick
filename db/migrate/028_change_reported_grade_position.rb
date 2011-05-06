class ChangeReportedGradePosition < ActiveRecord::Migration
  def self.up
    rename_column :reported_grades, :position, :predecessor_id
  end

  def self.down
    rename_column :reported_grades, :predecessor_id, :position
  end
end
