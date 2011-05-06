module UserBeast
  module ClassMethods
    def authors_of(posts)
      where(['id in (?)', posts.collect(&:user_id).uniq]).select('distinct *').index_by(&:id)
    end
  end

  def self.included(base)

    base.has_many                  :moderatorships, :dependent => :destroy
    base.has_many                  :forums, :through => :moderatorships, :order => 'name'

    base.has_many                  :forum_activities
    base.has_many                  :posts
    base.has_many                  :topics
    base.has_many                  :monitorships
    base.has_many                  :monitored_topics, :through => :monitorships,
    :conditions => ["monitorships.active = ?", true], :order => "topics.replied_at desc", :source => :topic, :include => [:last_post, :forum]

    base.extend ClassMethods
    base.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods
    def moderator_of?(forum)
      moderatorships.any?{|m| m.forum_id == (forum.is_a?(Forum) ? forum.id : forum)}
    end

    def may_create_forum_for?(discussable);false;end #overridden by staffer

    def may_access_forum_for?(discussable);false;end #overridden by staffer

    def recent_posts(discussable, options)
      posts.where(['posts.discussable_id = ? AND posts.discussable_type = ? AND posts.created_at > ?', discussable.id, discussable.klass, Time.now - 7.days]).limit(10).select(options[:select]).joins(options[:joins]).order(options[:order])
    end

    def recent_posts_of_interest
      Post.of_interest_to(self)
    end

    def owns?(forum)
      id == forum.owner_id
    end
  end
end
