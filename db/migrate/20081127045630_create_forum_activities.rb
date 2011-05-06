class CreateForumActivities < ActiveRecord::Migration
  def self.up
    create_table :forum_activities do |t|
      t.integer :user_id
      t.integer :posts_count, :default => 0
      t.integer :discussable_id
      t.string :discussable_type
      t.timestamps
    end
  end

  def self.down
    drop_table :forum_activities
  end
end
