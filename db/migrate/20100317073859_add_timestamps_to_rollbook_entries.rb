class AddTimestampsToRollbookEntries < ActiveRecord::Migration
  def self.up
    add_column :rollbook_entries, :created_at, :datetime
  end

  def self.down
    remove_column :rollbook_entries, :created_at
  end
end
