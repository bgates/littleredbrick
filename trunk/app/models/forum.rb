class Forum < ActiveRecord::Base

  acts_as_list
  def scope_condition
    "discussable_id=#{discussable_id} AND discussable_type='#{discussable_type}'"
  end
  belongs_to                    :discussable, :polymorphic => true
  belongs_to                    :owner, :class_name => 'User'
  validates_presence_of         :name, :owner_id
  validates_numericality_of     :position
  has_many                      :members, :class_name => 'User', 
                                :finder_sql => '#{self.member_conditions}'

  has_many                      :moderatorships, :dependent => :destroy do
    def update_list(ids)
      old_moderators = user_ids
      new_moderators = ids.reject{|m| old_moderators.include?(m)}
      new_moderators.each{|m| create(:user_id => m)}
      deletable = reject{|m| ids.include?(m.user_id)}
      deletable.each{|d| d.destroy}
    end
  end
  has_many                      :moderators, :through => :moderatorships,
                                :source => :user, 
                                :order => "users.last_name"
  has_many                      :topics, 
                                :order => 'sticky DESC, replied_at DESC', 
                                :dependent => :destroy do
    def prep(user, discussable, params)
      topic = build(params[:topic])
      topic.assign_protected(user, proxy_owner, params)
      topic.posts.first.set_restricted_values(user, discussable)
      topic
    end
  end

  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many                      :recent_topics, :class_name => 'Topic', 
                                :order => 'replied_at DESC' 

  has_many                      :posts, :order => "posts.created_at DESC" do
                                  def last
                                    @last_post ||= includes(:user).first
                                  end
                                end

  after_create :set_owner_as_moderator

  def self.find_all_for_discussable(discussable)
    where(['discussable_type = ? AND discussable_id = ?', discussable.klass, discussable.id])
  end

  def self.with_moderatorships
    select('forums.*, moderatorships.id AS moderatorship_id')
  end

  format_attribute :description

  def user_ids
    posts.map(&:user_id)
  end

  protected
    def member_conditions
      case discussable_type
      when 'Section'
        section = Section.find(discussable_id)
        select_clause << "((users.type = 'Teacher' AND users.id = #{section.teacher_id}) OR (users.type = 'Student' AND users.id IN (#{section.student_ids.join(',')})))"
      when 'school'
        school_condition
      when 'teachers'
        school_condition << " AND type = 'Teacher'"
      when 'admin'
        school_condition << " AND type = 'Staffer'"
      when 'staff'
        school_condition << " AND (type = 'Teacher' OR type = 'Staffer')"
      when 'help'
        select_clause << "type = 'Teacher' OR type = 'Staffer' OR type = 'G'"
      end
    end

    def school_condition
      select_clause << "school_id = #{discussable_id}"
    end

    def select_clause
      "SELECT \"users\".* FROM \"users\" WHERE "
    end

    def set_owner_as_moderator
      moderatorships.create(:user_id => owner_id)
    end
end

