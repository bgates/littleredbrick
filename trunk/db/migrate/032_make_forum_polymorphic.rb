class MakeForumPolymorphic < ActiveRecord::Migration
  def self.up
    rename_column :forums, :section_id, :discussable_id
    add_column :forums, :discussable_type, :string
    add_column :forums, :owner_id, :integer
    add_column :forums, :open, :boolean
    rename_column :posts, :section_id, :discussable_id
    add_column :posts, :discussable_type, :string
  end

  def self.down
    rename_column :forums, :discussable_id, :section_id
    remove_column :forums, :discussable_type
    remove_column :forums, :owner_id
    remove_column :forums, :open
    rename_column :posts, :discussable_id, :section_id
    remove_column :posts, :discussable_type
  end
end
