class RemoveAddressAndPhoneTables < ActiveRecord::Migration
  def self.up
    drop_table :addresses
    drop_table :phones
  end

  def self.down
    create_table :addresses do |t|
      t.column :addressable_id, :integer
      t.column :addressable_type, :string
      t.column :state, :string
      t.column :city, :string
      t.column :zip, :integer
    end

    create_table :phones do |t|
      t.column :user_id, :integer
      t.column :number, :integer
      t.column :kind_of, :string
    end
  end
end
