class DenormalizeSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :enrollment, :integer
    add_column :sections, :post_count, :integer
    add_column :sections, :forum_count, :integer
    Section.reset_column_information
    Section.find(:all).each do |s|
      s.post_count = Post.count(:all, :conditions => ['discussable_type = ? AND discussable_id = ?', 'Section', s.id])
      s.forum_count = Forum.count(:all, :conditions => ['discussable_type = ? AND discussable_id = ?', 'Section', s.id])
      s.save
    end
  end

  def self.down
    remove_column :sections, :enrollment
    remove_column :sections, :post_count
    remove_column :sections, :forum_count
  end
end
