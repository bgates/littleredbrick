class AddSeatingChart < ActiveRecord::Migration
  def self.up
    add_column :rollbook_entries, :x, :integer
    add_column :rollbook_entries, :y, :integer
  end

  def self.down
    remove_column :rollbook_entries, :x
    remove_column :rollbook_entries, :y
  end
end
