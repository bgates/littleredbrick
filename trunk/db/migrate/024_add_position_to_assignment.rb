class AddPositionToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :position, :integer
  end

  def self.down
    remove_column :assignments, :position
  end
end
