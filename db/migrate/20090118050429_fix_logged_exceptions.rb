class FixLoggedExceptions < ActiveRecord::Migration
  def self.up
    change_column :logged_exceptions, :message, :text
  end

  def self.down
  end
end
