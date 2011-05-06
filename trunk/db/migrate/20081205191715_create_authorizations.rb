class CreateAuthorizations < ActiveRecord::Migration
  def self.up
    drop_table :authorizations
    create_table :authorizations do |t|
      t.integer :user_id
      t.string :login, :limit => 40
      t.string :crypted_password, :limit => 40
      t.string :salt, :limit => 40
      t.integer :school_id
      t.string :login_key
      t.timestamps
    end

    User.all.each do |user|
      user.create_authorization(:login => user.login, :crypted_password => user.crypted_password, :salt => user.salt, :login_key => user.login_key, :school_id => user.school_id)
    end

    remove_column :users, :login
    remove_column :users, :crypted_password
    remove_column :users, :salt
    remove_column :users, :login_key
    remove_column :users, :created_at

    add_column :users, :last_login, :datetime
  end

  def self.down
    add_column :users, :login, :string, :limit => 40
    add_column :users, :crypted_password, :string, :limit => 40
    add_column :users, :salt, :string, :limit => 40
    add_column :users, :login_key, :string
    add_column :users, :created_at, :datetime

    remove_column :users, :last_login

    User.find(:all, :include => :authorization).each do |user|
      user.login = user.authorization.login
      user.crypted_password = user.authorization.crypted_password
      user.salt = user.authorization.salt
      user.login_key = user.authorization.login_key
      user.created_at = user.authorization.created_at
      user.save(false)
    end

    drop_table :authorizations
  end
end
