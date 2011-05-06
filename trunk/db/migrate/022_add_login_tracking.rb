class AddLoginTracking < ActiveRecord::Migration
  def self.up
    create_table :logins do |t|
      t.column :user_id, :integer
      t.column :login, :datetime
      t.column :logout, :datetime
    end

    add_column :schools, :teacher_limit, :integer
  end

  def self.down
    drop_table :logins
    remove_column :schools, :teacher_limit
  end
end
