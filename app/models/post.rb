class Post < ActiveRecord::Base
  def self.per_page() 25 end
#TODO: index by user/created_at
  belongs_to :discussable, :polymorphic => true
  belongs_to :forum
  belongs_to :forum_activity
  belongs_to :topic
  belongs_to :user
  before_save :remove_obscenities
  format_attribute :body #TODO: does format_attribute still work?
  before_create { |r| r.forum_id = r.topic.forum_id }
  after_create  :update_cached_fields, :set_activity
  after_destroy :update_cached_fields, :set_activity

  validate :check_html, :topic_unlocked?
  validates_presence_of :user_id, :body
  attr_accessible :body

  @@query_options = {
    :per_page => 25,
    :select => "posts.*, topics.title as topic_title, forums.name as forum_name",
    :joins => "inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id",
    :order => "posts.created_at desc"
  }

  def date
    updated_at.strftime("%a %b %d")
  end

  def editable_by?(user)
    user.id == user_id || user.moderator_of?(topic.forum_id)
  end

  def self.count_for_user(user)
    where(['user_id = ?', user.id]).count('id')
  end

  def self.of_interest_to(user)
    where(["((posts.discussable_type = 'Section' AND posts.discussable_id IN (?)) OR (posts.discussable_type IN (?) AND posts.discussable_id = ?)) AND posts.created_at > ?", user.section_ids, user.discussables, user.school_id, Date.today - 7]).includes([:topic, :forum, :user]).group_by(&:topic_id).collect{|topic, posts| posts.max{|a, b| a.created_at <=> b.created_at }}
  end

  def self.monitored(reader_id, page)
    conditions = ["monitorships.user_id = ? and posts.user_id != ? and monitorships.active = ?", reader_id, reader_id, true]
    options = @@query_options.merge(:conditions => conditions, :page => page, :count => { :select => 'posts.id' })
    options[:joins] += " inner join monitorships on monitorships.topic_id = topics.id"
    paginate options
  end

  def self.paginate_for_topic(id, page, discussable)
    scoped_by_topic_id(id).paginate :include => [{:user => [:forum_activities, :moderatorships]}], :order => "posts.created_at", :per_page => 25, :page => page, :conditions => ['posts.discussable_type = :type AND posts.discussable_id = :id AND forum_activities.discussable_type = :type AND forum_activities.discussable_id = :id', {:type => discussable.klass, :id => discussable.id}]
  end

  def self.recent(n = 5, discussable = nil)
    result = select("posts.*, users.*, topics.title as topic_title, forums.name as forum_name").joins("inner join users on posts.user_id = users.id inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id").order("posts.created_at desc").limit(n)
    if discussable
      result = result.where(['posts.discussable_id = ? AND posts.discussable_type = ?', discussable.id, discussable.klass]) 
    end
    result
  end

  def self.recent_by_user
    where(['updated_at > ?', 1.hour.ago]).select('user_id').group('user_id').count
  end

  def self.restrict_by(params)
    restricted = self
    params[:user_id] = params[:reader_id]
    [:forum_id, :topic_id, :user_id].each do |attr|
      if params[attr]
        restricted = restricted.where(["posts.#{attr} = ?", params[attr]])
      end
    end
    options = @@query_options.merge(:page => params[:page])
    restricted.paginate options
  end

  def self.search(term, page)
    options = @@query_options.merge(:page => page)
    where(["LOWER(posts.body) LIKE ?", "%#{term}%"]).paginate options
  end

  def set_restricted_values(user, discussable)
    self.user, self.discussable_id, self.discussable_type = user, discussable.id, discussable.klass
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :topic_title << :forum_name
    super
  end

  protected
    # using count isn't ideal but it gives us correct caches each time
    def update_cached_fields
      Forum.update_all ['posts_count = ?', Post.count(:id, :conditions => {:forum_id => forum_id})], ['id = ?', forum_id]
      topic.update_cached_post_fields(self)
      if discussable_type == 'Section'
        s = Section.find(discussable_id)
        frozen??  s.decrement!(:posts_count) : s.increment!(:posts_count)
      end
    end

    def set_activity
      activity = ForumActivity.find_or_create(user_id, discussable_type, discussable_id)
      frozen??  activity.decrement!(:posts_count) : activity.increment!(:posts_count)
    end

    def remove_obscenities
      self.body = smurf_text(body)
      self.body_html = smurf_text(body_html)
    end
    
    def check_html
      begin
        REXML::Document.new("<tag>#{self.body_html}</tag>") 
        #<tag> is used bc xml doc must have one enclosing tag
      rescue REXML::ParseException => exception
        errors.add(:body, 'is not valid HTML.')
      end
    end

    def topic_unlocked?
      if topic && topic.locked? 
        errors.add(:base, 'This topic is locked, so no posts may be added.')
      end
    end
end
