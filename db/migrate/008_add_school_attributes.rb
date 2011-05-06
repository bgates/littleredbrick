class AddSchoolAttributes < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    add_column :schools, :low_grade, :string, :limit => 2
    add_column :schools, :high_grade, :string, :limit => 2
    add_column :schools, :low_period, :integer
    add_column :schools, :high_period, :integer
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    remove_column :schools, :low_grade
    remove_column :schools, :high_grade
    remove_column :schools, :low_period
    remove_column :schools, :high_period
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end
end
