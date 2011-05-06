class AddDueDateToGrade < ActiveRecord::Migration
  def self.up
    add_column :grades, :date_due, :datetime
  end

  def self.down
    remove_column :grades, :date_due
  end
end
