class Topic < ActiveRecord::Base
  belongs_to            :forum
  belongs_to            :user
  has_many              :monitorships
  has_many              :monitors, :through => :monitorships, :conditions =>
    ["monitorships.active = ?", true], :source => :user, :order => "users.last_name"

  has_many              :posts, :order => "posts.created_at", :dependent => :destroy
  has_one               :last_post, :class_name => 'Post'
  has_many              :voices, :through => :posts, :source => :user, :uniq => true

  belongs_to            :replied_by_user, :foreign_key => "replied_by", :class_name => "User"

  validates_presence_of :forum_id, :user_id, :title
  validates_associated  :posts, :on => :create

  before_create         :set_default_replied_at_and_sticky
  before_update         :check_for_changing_forums
  after_save            :update_forum_counter_cache
  after_destroy         :update_forum_counter_cache

  attr_accessible :title, :first_post, :body
  # to help with the create form
  attr_accessor :body, :first_post

  def self.paginate_for_forum(forum, page)
    scoped_by_forum_id(forum.id).paginate :per_page => 25, 
    :page => page, :include => :replied_by_user, :order => 'sticky desc, replied_at desc'
  end

  def assign_protected(user, forum, params)
    self.user = user if new_record?
    # admins and moderators can sticky and lock topics
    return unless user.moderator_of?(forum) or user.is_a?(Staffer)#admin?
    self.sticky, self.locked = params[:topic][:sticky], params[:topic][:locked]
    # only admins can move
    return unless user.id == forum.owner_id
    forum_id = params[:forum_id] if params[:forum_id]
  end

  def hit!
    self.class.increment_counter :hits, id
  end

  def sticky?() sticky == 1 end

  def views() hits end

  def paged?() posts_count > Post.per_page end

  def last_page
    [(posts_count.to_f / Post.per_page).ceil.to_i, 1].max
  end

  def editable_by?(user)
    (user.id == user_id || user.moderator_of?(forum))#|| user.admi
  end

  def update_cached_post_fields(post)
    # these fields are not accessible to mass assignment
    if post.frozen? && posts_count == 1
      destroy
    else
      last_post = post.frozen? ? posts.last : post
      if last_post
        Topic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?, posts_count = ?', last_post.created_at, last_post.user_id, last_post.id, posts.count], ['id = ?', id])
      else
        Topic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?, posts_count = ?', nil, nil, nil, 1], ['id = ?', id])
      end
    end
  end

  def first_post=(post_attribute_array)
    posts.build(post_attribute_array)
    posts[0].forum_id = forum_id
    self.body = post_attribute_array[:body]
  end
  protected
    def set_default_replied_at_and_sticky
      self.replied_at = Time.now.utc
      self.sticky   ||= 0
      forum.open || forum.owner_id == self.user_id
    end

    def set_post_forum_id
      Post.update_all ['forum_id = ?', forum_id], ['topic_id = ?', id]
    end

    def check_for_changing_forums
      old = Topic.find(id)
      @old_forum_id = old.forum_id if old.forum_id != forum_id
      true
    end

    # using count isn't ideal but it gives us correct caches each time
    def update_forum_counter_cache
      @forum_conditions = ['topics_count = ?', Topic.count(:id, :conditions => "forum_id = #{forum_id}")]
      account_for_forum_change
      Forum.update_all @forum_conditions, ['id = ?', forum_id]
      @old_forum_id = nil
      set_section_topic_count
    end

    def account_for_forum_change
      if !frozen? && @old_forum_id && @old_forum_id != forum_id
        set_post_forum_id
        Forum.update_all ['topics_count = ?, posts_count = ?',
          Topic.where(["forum_id = ?", @old_forum_id]).count,
          Post.where(["forum_id = ?", @old_forum_id]).count], ['id = ?', @old_forum_id]
        @forum_conditions.first << ", posts_count = ?"
        @forum_conditions       << Post.where(["forum_id = ?", forum_id]).count
      end
    end

    def set_section_topic_count
      if forum.discussable_type == 'Section'
        if frozen? 
          Section.find(forum.discussable_id).decrement!(:topics_count) 
        else
          Section.find(forum.discussable_id).increment!(:topics_count)
        end
      end
    end
end
