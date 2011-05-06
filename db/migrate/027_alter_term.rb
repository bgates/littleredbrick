class AlterTerm < ActiveRecord::Migration
  def self.up
    remove_column :terms, :name
  end

  def self.down
    add_column :terms, :name, :string
  end
end
