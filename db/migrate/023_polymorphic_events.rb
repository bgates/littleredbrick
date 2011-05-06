class PolymorphicEvents < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.column :event_id, :integer, :null => false
      t.column :invitable_id, :integer, :limit => 9, :null => false
      t.column :invitable_type, :string, :limit => 10, :null => false
    end
    add_column :events, :creator, :integer, :limit => 9
    change_column :events, :date, :date, :null => false, :default => 0
  end

  def self.down
    drop_table :invites
    remove_column :events, :creator
    change_column :events, :date, :datetime
  end
end
