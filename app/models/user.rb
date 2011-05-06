class User < ActiveRecord::Base
  include UserBeast

  belongs_to                :school
  has_and_belongs_to_many   :roles
  has_one                   :address, :as => :addressable
  has_many                  :events, :as => :invitable, :dependent => :destroy
  has_many                  :upcoming_events, :as => :invitable, :class_name => 'Event',
                            :order => 'date DESC', :limit => 3
  has_many                  :logins
  attr_accessor             :signup, :reauthorize
  has_one                   :authorization, :dependent => :destroy

  validates_associated      :authorization
  validates_presence_of     :first_name, :last_name
  validates_uniqueness_of   :id_number, :scope => [:school_id, :type], :allow_blank => true
  validates_numericality_of :id_number, :allow_nil => true
  validates_format_of       :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true
  validates_presence_of     :email, :message => "is required so we can contact you about billing. We won't give your email to anyone else.", :if => Proc.new{|user| user.signup}
    
  before_validation           :strip_names
  before_validation           :add_default_attributes, :unless => Proc.new{|user| user.signup}, :on => :create
  before_validation           :reset!, :if => Proc.new{|user| user.reauthorize == '1'}, :on => :update
  after_save                  :fix_initial_authorization, :if => Proc.new{|user| user.signup}
  after_save                  :update_auth, :if => Proc.new{|user| user.reauthorize == 'save' && user.errors.empty?}
  delegate :login, :to => :authorization

  def admin?;false;end #overridden by staffer

  # Enable bulk addition of user information, automatically creating logins and passwords
  def add_default_attributes
    self.id_number ||= (self.class.where(['school_id = ?', school_id]).maximum('id_number') || 0) + 1
   (authorization || build_authorization).add_default_attributes(self)
  end

  def universal_events(start, finish, track_or_tracks)
    Event.for_person(id, start, finish) +
    Event.for_school(school_id, start, finish) + 
    MarkingPeriod.on_calendar(track_or_tracks, start, finish)
  end

  def authorization=(auth)
    (authorization || build_authorization).attributes = auth.merge(:school_id => school_id)
    self.reauthorize = 'save'
  end

  def self.default(params)
    default_attribute = params[:first_name].strip + params[:last_name].strip rescue ''
    params[:authorization] ||= {:login => default_attribute.downcase}
    params[:authorization].merge!(:password => params[:authorization][:login], :password_confirmation => params[:authorization][:login], :school_id => params[:school_id])
    new(params)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_name=(name)
    first, last = name.split(' ')
    write_up(first,last)
  end

  def has_default_login?
    full_name.downcase.sub(/\s/, '') == login
  end

  def last_first; "#{last_name}, #{first_name}"; end

  def last_first=(name)
    last, first = name.split(/,\s*/)
    write_up(first, last)
  end

  def may_view_family_events_for?(invitable_id)
    false
  end

  def may_view_personal_events_for?(creator_id)
    id == creator_id
  end

  def never_logged_in?
    last_login.nil?
  end

  def note_wrong_login
    errors.add(:base, "The login for a new user is created by merging the user's names. If your school has two people with the same name, you will need to create a different login for one of them.") unless authorization.errors[:login].blank?
  end

  def has_invalid_children?
    false
  end

  def self.search(query, options = {})
    where(build_search_conditions(query, options.delete(:school_id)))
  end

  def reset!
    authorization.login = (first_name + last_name).downcase
    authorization.password = authorization.password_confirmation = authorization.login
    self.reauthorize = 'save'
  end

  def self.build_search_conditions(query, school)
    query && ['(LOWER(last_name) LIKE :q OR LOWER(first_name) LIKE :q) AND school_id = :s', {:q => "%#{query.downcase}%", :s => school}]
  end

  def self.import_with_authorizations(users)
    import(users, :validate => false)
    new_users = where(['school_id = ?', users.first.school_id]).includes(:authorization).select{|u| u.authorization.nil?}
    new_users.each do |u|
      param = (u.first_name + u.last_name).downcase
      u.build_authorization(:login => param, :password => param, :school_id => u.school_id)
      u.authorization.encrypt_password
    end
    Authorization.import(new_users.collect{|u|u.authorization}, :validate => false)
  end

  def quick_valid?(existing_auth)
    errors.add(:first_name, 'must not be blank') if first_name.blank?
    errors.add(:last_name, 'must not be blank') if last_name.blank?
    errors.add(:login, 'is being used by someone else at the school') if existing_auth.include?(login)
    errors.empty?
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :login_key << :crypted_password << :salt
    super
  end

  def may_participate_in?(discussable); true; end

  def teaches?(section);false;end #overridden by staffer

  protected

    def id_required?; true; end #override by parent, maybe staff

    def fix_initial_authorization
      authorization.update_attribute(:school_id, school_id)
    end

    def section_or_school_track
      sections.empty?? school.current_default_track : sections.first.track
    end

    def strip_names
      first_name.strip! if first_name
      last_name.strip! if last_name
    end

    def update_auth
      self.authorization.save
    end

    def write_up(first,last)
      write_attribute('first_name', first.strip) if first
      write_attribute('last_name', last.strip) if last
    end
end

