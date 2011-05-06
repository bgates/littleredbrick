class School < ActiveRecord::Base
  has_many                  :users, :order => 'last_name', 
                            :dependent => :destroy
  has_many                  :authorizations
  has_many                  :students, 
                            :order => 'users.last_name, users.first_name'
  has_many                  :teachers, :order => 'last_name'
  has_many                  :sections, :through => :teachers
  has_many                  :staffers
  has_many                  :staff, :class_name => 'User', :order => 'last_name', :conditions => "users.type = 'Staffer' OR users.type = 'Teacher'"
  has_many                  :admins, :class_name => 'User', :include => 'roles', :conditions => "roles.title = 'admin'"
  has_many                  :parents, :order => 'users.last_name'
  has_many                  :departments, :dependent => :destroy, 
                            :order => 'departments.name', 
                            :include => 'subjects'
  accepts_nested_attributes_for :departments, :reject_if => :all_blank
  has_many                  :terms, :dependent => :destroy
  has_many                  :reported_grades, :through => :terms
  has_one                   :current_term, :class_name => 'Term'
  has_many                  :events, :as => :invitable, 
                            :dependent => :destroy
  has_many                  :upcoming_events, :as => :invitable, :class_name => 'Event',
                            :order => 'date DESC', :conditions => ['date BETWEEN (?) AND (?)', Date.today, 2.weeks.from_now]
  has_many                  :forums, 
                            :foreign_key => :discussable_id, 
                            :conditions => 'forums.discussable_type = \'#{type}\'',
                            :order => 'position'
  has_many                  :forum_activities, :foreign_key => :discussable,
                            :conditions => 'forum_activities.discussable_type = \'#{type}\''
  has_many                  :posts,
                            :foreign_key => :discussable_id,
                            :conditions => 'posts.discussable_type = \'#{type}\''
  validates_presence_of     :name, :domain_name
  validates_uniqueness_of   :domain_name, 
                            :message => "is in use by another school. Please choose a different one."
  validates_format_of       :domain_name, 
                            :with => /^\w{3,50}$/, 
                            :message => "must be all alphanumeric characters (letters or numbers) and at least 3 characters long", 
                            :unless => Proc.new{|s| s.domain_name.blank?}
  validates_exclusion_of    :domain_name, 
                            :in => ['www', 'blog', 'signup'],
                            :message => "is not allowed"
  attr_accessor             :contact, :type, :discussable_id

  after_create              :send_welcome_email, :if => :has_contact?
  after_create              :make_admin, :if => :has_contact?
  after_destroy             :remove_forums
  
  def has_not_been_setup?; !setup; end
  
  def mark_as_setup!; update_attribute(:setup, true); end
  
  def absence_codes(short_code = true)
    short_code ? Absence::SHORT_CODE : Absence::CODES
  end

  def add_parents_bulk
    children  = students.includes([:authorization, :parents]).select{|s| s.parents.empty? && s.login == s.full_name.sub(/\s/,'').downcase}.sort_by{|s| s.login }
  
    bulk_parents = initialize_parents_from(children)

    transaction do
      parent_import(bulk_parents)
  
      saved_parents = parents.includes([:authorization, :children]).select{|p| p.children.empty?}.sort_by{|p| p.login }
      values = []

      children.each do |child|
        child_parents, saved_parents = saved_parents.partition{|p| p.login.include?(child.login + '_')}
        child_parents.each{|cp| values << "(#{cp.id}, #{child.id})"}
      end
      ActiveRecord::Base.connection.insert("INSERT INTO parents_students (parent_id, student_id) VALUES #{values.join(',')}")
    end
  end

  def current_default_track
    current_term.tracks.first
  end

  def grade_range
    low_grade..high_grade
  end

  def initial_user(params)
    if params[:teacher] == 'yes' || params[:group].nil? 
      teachers.build(params[:user]) 
    else
      staffers.build(params[:user])
    end
  end
  
  def initialize_parents_from(children)
    parent_tags = ['_father', '_mother']
    children.map do |child|
      parent_tags.map do |parent|
        p = Parent.new(:school_id => id, :first_name => child.login, :last_name => parent)
        p.build_authorization(:login => child.login + parent, :password => child.login + parent, :school_id => id)
        p.authorization.encrypt_password
        p
      end
    end.flatten
  end

  def klass
    to_param
  end

  def may_add_more_teachers?(force_reload = false)
    teacher_limit > teachers(force_reload).length
  end
 
  def members(page)
    User.paginate :include => 'forum_activities', :conditions => membership_conditions, :page => page, :per_page => 10
  end

  def membership
    User.count :all, :include => 'forum_activities', :conditions => membership_conditions
  end

  def parent_import(bulk_parents)
    User.import bulk_parents, :validate => false
    bulk_authorizations = bulk_parents.collect{|p| p.authorization}
    created_parents = Parent.find_all_by_school_id(self.id)
    bulk_authorizations.each do |auth|
      auth.user_id = created_parents.detect{|p| p.first_name + p.last_name == auth.login}.id
    end
    Authorization.import bulk_authorizations, :validate => false
  end

  def set_generic_departments
    Department.generic_choices.each do |dept|
      departments.build(dept.attributes)
      dept.subjects.each{|sub| departments.last.subjects.build(sub.attributes)}
    end
  end

  def to_param
    type || super
  end

  protected

    def has_contact?
      !@contact.nil?
    end

    def make_admin
      @contact.make_admin if @contact.is_a?(Teacher)
    end

    def membership_conditions                                     
      ['forum_activities.discussable_type = ? AND forum_activities.discussable_id = ?', type , id]
    end

    def remove_forums
      Forum.where('discussable_id = ? AND discussable_type != ?', id, 'Section').destroy_all
    end

    def send_welcome_email
      @contact.save
      UserNotifier.welcome_email(self, @contact).deliver
      UserNotifier.school_creation_notification(self, @contact).deliver
    end
end
