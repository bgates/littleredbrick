class AgainWithTheIndexes < ActiveRecord::Migration
  def self.up
    change_column :schools, :domain_name, :string, :limit => 50
    change_column :schools, :teacher_limit, :integer, :limit => 5
    add_index :schools, :domain_name

    change_column :authorizations, :login, :string, :limit => 15
    add_index :authorizations, [:login, :school_id]
    add_index :authorizations, :user_id
  end

  def self.down
    remove_index :schools, :domain_name

    remove_index :authorizations, [:login, :school_id]
    remove_index :authorizations, :user_id
  end
end
