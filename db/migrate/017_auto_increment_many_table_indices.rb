class AutoIncrementManyTableIndices < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    execute "ALTER TABLE addresses MODIFY id int(6) not null auto_increment"
    execute "ALTER TABLE assignments MODIFY id int(7) auto_increment"
    execute "ALTER TABLE departments MODIFY id int(4) auto_increment"
    execute "ALTER TABLE grades MODIFY id int(9) auto_increment"
    execute "ALTER TABLE marking_periods MODIFY id int(4) auto_increment"
    execute "ALTER TABLE milestones MODIFY id int(8) auto_increment"
    execute "ALTER TABLE roles MODIFY id int(3) auto_increment"
    execute "ALTER TABLE rollbook_entries MODIFY id int(7) auto_increment"
    execute "ALTER TABLE schools MODIFY id int(3) auto_increment"
    execute "ALTER TABLE sections MODIFY id int(5) auto_increment"
    execute "ALTER TABLE sessions MODIFY id int(7) auto_increment"
    execute "ALTER TABLE subjects MODIFY id int(4) auto_increment"
    execute "ALTER TABLE users MODIFY id int(9) auto_increment"
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end
end
