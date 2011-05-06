class CreateAddresses < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    create_table "addresses", :force => true do |t|
      t.column "addressable_id", :integer, :default => 0, :null => false
      t.column "addressable_type", :string, :default => "", :null => false
      t.column "street", :string
      t.column "city", :string, :limit => 60
      t.column "state", :string, :limit => 2
      t.column "zip", :string, :limit => 9
    end
    
    remove_column :schools, :street
    remove_column :schools, :city
    remove_column :schools, :state
    remove_column :schools, :zip
  execute 'SET FOREIGN_KEY_CHECKS = 1'
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    drop_table :addresses
    
    add_column :schools, :street, :string
    add_column :schools, :city, :string, :limit => 60
    add_column :schools, :state, :string, :limit => 2
    add_column :schools, :zip, :string, :limit => 9
    
    execute 'SET FOREIGN_KEY_CHECKS = 1'    
  end
end
