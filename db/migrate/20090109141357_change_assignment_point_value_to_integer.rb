class ChangeAssignmentPointValueToInteger < ActiveRecord::Migration
  def self.up
    change_column :assignments, :point_value, :integer, :default => 0
  end

  def self.down
    change_column :assignments, :point_value, :string, :default => ''
  end
end
