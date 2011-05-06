class ChangeToBooleans < ActiveRecord::Migration
  def self.up
    rename_column :forums, :open, :int_open
    rename_column :monitorships, :active, :int_active
    rename_column :schools, :setup, :int_setup
    rename_column :sections, :current, :int_current
    rename_column :topics, :locked, :int_locked
    
    add_column :forums, :open, :boolean
    add_column :monitorships, :active, :boolean
    add_column :schools, :setup, :boolean
    add_column :sections, :current, :boolean
    add_column :topics, :locked, :boolean
    
    Forum.update_all "open = true", "int_open = 1"
    Forum.update_all "open = false", "int_open = 0"
    
    Monitorship.update_all "active = true", "int_active = 1"
    Monitorship.update_all "active = false", "int_active = 0"
    
    School.update_all "setup = true", "int_setup = 1"
    School.update_all "setup = false", "int_setup = 0"
    
    Section.update_all "current = true", "int_current = 1"
    Section.update_all "current = false", "int_current = 0"
    
    Topic.update_all "locked = true", "int_locked = 1"
    Topic.update_all "locked = false", "int_locked = 0"
  end

  def self.down
    rename_column :forums, :open, :bool_open
    rename_column :monitorships, :active, :bool_active
    rename_column :schools, :setup, :bool_setup
    rename_column :sections, :current, :bool_current
    rename_column :topics, :locked, :bool_locked
  
    add_column :forums, :open, :integer, :limit => 1
    add_column :monitorships, :active, :integer, :limit => 1
    add_column :schools, :setup, :integer, :limit => 1
    add_column :sections, :current, :integer, :limit => 1
    add_column :topics, :locked, :integer, :limit => 1
    
    Forum.update_all "open = 1", "bool_open = true"
    Forum.update_all "open = 0", "bool_open = false"
    
    Monitorship.update_all "active = 1", "bool_active = true"
    Monitorship.update_all "active = 0", "bool_active = false"
    
    School.update_all "setup = 1", "bool_setup = true"
    School.update_all "setup = 0", "bool_setup = false"
    
    Section.update_all "current = 1", "bool_current = true"
    Section.update_all "current = 0", "bool_current = false"
    
    Topic.update_all "locked = 1", "bool_locked = true"
    Topic.update_all "locked = 0", "bool_locked = false"
  end
end
