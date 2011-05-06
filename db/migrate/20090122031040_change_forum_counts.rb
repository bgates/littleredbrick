class ChangeForumCounts < ActiveRecord::Migration
  def self.up
    rename_column :sections, :forums_count, :topics_count
  end

  def self.down
    rename_column :sections, :topics_count, :forums_count
  end
end
