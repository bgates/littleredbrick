class RemoveTempBooleanColumns < ActiveRecord::Migration
  def self.up
    remove_column :sections, :int_current
    remove_column :forums, :int_open
    remove_column :schools, :int_setup
    remove_column :monitorships, :int_active
    remove_column :topics, :int_locked
  end

  def self.down
  end
end
