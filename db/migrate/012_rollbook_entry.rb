class RollbookEntry < ActiveRecord::Migration
  def self.up
    rename_table :sections_students, :rollbook_entries
    add_column :rollbook_entries, :position, :integer
    add_column :rollbook_entries, :id, :integer, :null => false
    add_index :rollbook_entries, :id, :unique
  end

  def self.down
    rename_table :rollbook_entries, :sections_students
    remove_column :sections_students, :position
    remove_column :sections_students, :id
  end
end
