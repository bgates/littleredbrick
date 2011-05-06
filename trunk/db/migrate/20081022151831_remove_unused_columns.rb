class RemoveUnusedColumns < ActiveRecord::Migration
  def self.up
    remove_column :users, :birth_date
    remove_column :users, :year
    remove_column :users, :updated_at
    remove_column :users, :posts_count
    remove_column :users, :screen_name
    remove_column :users, :last_seen_at

    rename_column :grades, :date_submitted, :updated_at

    rename_column :logins, :login, :created_at


  end

  def self.down
    add_column :users, :birth_date, :date
    add_column :users, :year, :integer
    add_column :users, :updated_at, :datetime
    add_column :users, :posts_count, :integer
    add_column :users, :screen_name, :string
    add_column :users, :last_seen_at, :datetime

    rename_column :grades, :updated_at, :date_submitted

    rename_column :logins, :created_at, :login
  end
end
