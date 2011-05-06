class CreateAbsences < ActiveRecord::Migration
  def self.up
    create_table :absences do |t|
      t.column :rollbook_entry_id, :int
      t.column :student_id, :int
      t.column :section_id, :int
      t.column :code, :int
      t.column :date, :date
    end
  end

  def self.down
    drop_table :absences
  end
end
