class ChangeSectionTimes < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    change_column :sections, :time, :string, :limit => 3
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    change_column :sections, :time, :time
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end
end
