class AddSetupCheckToSchool < ActiveRecord::Migration
  def self.up
    rename_column :schools, :phone, :setup
    change_column :schools, :setup, :boolean
  end

  def self.down
    rename_column :schools, :setup, :phone
    change_column :schools, :phone, :string
  end
end
