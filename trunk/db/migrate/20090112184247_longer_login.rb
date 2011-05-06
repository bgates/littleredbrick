class LongerLogin < ActiveRecord::Migration
  def self.up
    change_column :authorizations, :login, :string, :limit => 60
  end

  def self.down
  end
end
