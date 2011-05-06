class AddAliasForTeachers < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    add_column :users, :screen_name, :string
    execute 'SET FOREIGN_KEY_CHECKS = 1'  
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    remove_column :users, :screen_name
    execute 'SET FOREIGN_KEY_CHECKS = 1'  
  end
end
