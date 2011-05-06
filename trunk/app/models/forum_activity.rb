class ForumActivity < ActiveRecord::Base
  belongs_to :user
  belongs_to :discussable, :polymorphic => true
  after_create :remove_updated_at

  def self.find_or_create(user, type, id)
    self.find_or_create_by_user_id_and_discussable_type_and_discussable_id(user, type, id)
  end

  def self.for(section)
    Hash.new(new).merge(section.forum_activities.select('user_id, posts_count').index_by(&:user_id))
  end

  protected
  def remove_updated_at
    ForumActivity.update_all(['updated_at = ?', nil], ['id = ?',id])
  end
end
