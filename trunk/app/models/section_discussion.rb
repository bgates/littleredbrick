module SectionDiscussion

  def self.included(base)

    base.has_many              :forums, :as => :discussable,
                               :dependent => :destroy, :order => :position
    base.has_many              :forum_activities, :as => :discussable

    base.has_many              :posts, :as => :discussable, 
                               :dependent => :destroy
    base.has_one               :last_post, :as => :discussable,
                               :class_name => "Post", :order => :created_at
    base.after_create          :set_teacher_forum_activity

    base.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods

    def klass; self.class.to_s; end
    def type; self.class.to_s; end

    def members(page)
      User.paginate :include => 'forum_activities', :conditions => ['forum_activities.discussable_type = ? AND forum_activities.discussable_id = ?', 'Section', id], :page => page
    end

    def membership
      enrollment + 1
    end

    def posts_count
      forums.sum 'posts_count'
    end

    def topics_count
      forums.sum 'topics_count'
    end

    protected

      def set_teacher_forum_activity
        ForumActivity.create(:user_id => teacher_id, 
                    :discussable_type => 'Section',  :discussable_id => id)
      end
  end
end
