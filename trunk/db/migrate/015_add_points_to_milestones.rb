class AddPointsToMilestones < ActiveRecord::Migration
  def self.up
    rename_column :milestones, :score, :earned
    add_column :milestones, :possible, :integer, :default => 0
    change_column :milestones, :earned, :decimal, :precision => 5, :scale => 1, :default => 0
  end

  def self.down
    remove_column :milestones, :possible
    rename_column :milestones, :earned, :score
    change_column :milestones, :score, :string, :length => 4
  end
end
