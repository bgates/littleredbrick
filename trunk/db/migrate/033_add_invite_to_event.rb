class AddInviteToEvent < ActiveRecord::Migration
  def self.up
    add_column :events, :invitable_type, :string
    add_column :events, :invitable_id, :integer
    rename_column :events, :creator, :creator_id
  end

  def self.down
    remove_column :events, :invitable_type
    remove_column :events, :invitable_id
    rename_column :events, :creator_id, :creator
  end
end
