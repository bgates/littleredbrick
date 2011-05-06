class AddPositionToMarkingPeriod < ActiveRecord::Migration
  def self.up
    add_column :marking_periods, :position, :integer
  end

  def self.down
    remove_column :marking_periods, :position
  end
end
