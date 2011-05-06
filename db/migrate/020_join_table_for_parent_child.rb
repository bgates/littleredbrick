class JoinTableForParentChild < ActiveRecord::Migration
  def self.up
    add_column :tracks, :archive, :date
    create_table :parents_students, :id => false do |t|
      t.column 'parent_id', :integer, :null => false
      t.column 'student_id', :integer, :null => false
    end
    remove_column :users, :parent_of
  end

  def self.down
    remove_column :tracks, :archive
    drop_table :parents_students
    add_column :users, :parent_of, :integer
  end
end
