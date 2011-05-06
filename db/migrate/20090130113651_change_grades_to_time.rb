class ChangeGradesToTime < ActiveRecord::Migration
  def self.up
    change_column :grades, :date_due, :date
  end

  def self.down
  end
end
