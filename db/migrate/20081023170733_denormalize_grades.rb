class DenormalizeGrades < ActiveRecord::Migration
  def self.up
    add_column :grades, :section_id, :integer
    add_index :grades, :section_id
  end

  def self.down
    remove_column :grades, :section_id
  end
end
