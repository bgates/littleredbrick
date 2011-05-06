class AddSectionToForum < ActiveRecord::Migration
  def self.up
    add_column :forums, :section_id, :integer
  end

  def self.down
    remove_column :forums, :section_id
  end
end
