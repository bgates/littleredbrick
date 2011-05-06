class CreateMilestonesAndMarkingPeriods < ActiveRecord::Migration
  def self.up
    create_table :milestones do |t|
      t.column :student_id, :integer
      t.column :section_id, :integer
      t.column :description, :string, :limit => 20
      t.column :score, :string, :limit => 4
    end
    create_table :marking_periods do |t|
      t.column :school_id, :integer
      t.column :start, :date
      t.column :finish, :date
    end
  end

  def self.down
    drop_table :milestones
    drop_table :marking_periods
  end
end
