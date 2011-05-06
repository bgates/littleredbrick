class AddDefaultsToSectionCounters < ActiveRecord::Migration
  def self.up
    rename_column :sections, :post_count, :posts_count
    rename_column :sections, :forum_count, :forums_count
    change_column :sections, :enrollment, :integer, :default => 0
    change_column :sections, :posts_count, :integer, :default => 0
    change_column :sections, :forums_count, :integer, :default => 0
  end

  def self.down
    rename_column :sections, :posts_count, :post_count
    rename_column :sections, :forums_count, :forum_count
  end
end
