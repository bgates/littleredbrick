class CreateLogins < ActiveRecord::Migration
  def self.up
    create_table :logins do |t|
      t.column :user_id, :integer
      t.column :login, :datetime
      t.column :logout, :datetime
    end
  end

  def self.down
    drop_table :logins
  end
end
