class MovePeriodsFromSchoolToTerm < ActiveRecord::Migration
  def self.up
    remove_column :schools, :low_period
    remove_column :schools, :high_period
    add_column :terms, :low_period, :integer, :limit => 1
    add_column :terms, :high_period, :integer, :limit => 2
  end

  def self.down
    remove_column :terms, :low_period
    remove_column :terms, :high_period
    add_column :schools, :low_period, :integer, :limit => 1
    add_column :schools, :high_period, :integer, :limit => 2
  end
end
