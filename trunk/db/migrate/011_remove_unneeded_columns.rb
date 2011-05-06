class RemoveUnneededColumns < ActiveRecord::Migration
  def self.up
    remove_column :users, :middle_name
    remove_column :users, :activation_code
    remove_column :users, :activated_at
    remove_column :users, :password_reset_code
    remove_column :users, :position
    remove_column :users, :home_language
    change_column :users, :grade, :integer, :limit => 2
    drop_table :breadcrumbs
    drop_table :map_points
    drop_table :pages
    drop_table :sidebars
  end

  def self.down
    add_column :users, :middle_name, :string, :limit => 25
    add_column :users, :activation_code, :string, :limit => 40
    add_column :users, :activated_at, :datetime
    add_column :users, :password_reset_code, :string, :limit => 40
    add_column :users, :position, :string, :limit => 25
    add_column :users, :home_language, :string, :limit => 20
    change_column :users, :grade, :string, :limit => 3
    add_column :users, :home_language, :string, :limit => 20
    create_table :breadcrumbs do |t|
      t.column :name, :string, :limit => 25
      t.column :parent_id, :integer
    end  
    create_table :map_points do |t|
      t.column :lat, :float
      t.column :lon, :float
      t.column :kind_of, :string, :limit => 10
    end
    create_table :pages do |t|  
      t.column :controller, :string, :limit => 20
      t.column :action, :string, :limit => 20
      t.column :title, :string, :limit => 40
      t.column :phone_number, :integer
    end
    create_table :sidebars do |t|
      t.column :title, :string, :limit => 100
      t.column :description, :text
      t.column :url, :string, :limit => 100
    end  
  end
end
