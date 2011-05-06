class Parent < User
  has_and_belongs_to_many :children, :class_name => 'Student',
                          :join_table => 'parents_students',
                          :association_foreign_key => 'student_id',
                          :foreign_key => 'parent_id'
  #before_destroy          :prevent_orphan
  attr_accessor           :gender, :child
  before_validation       :new_children_added_correctly, :on => :update

  #def prevent_orphan is there ever a legitimate reason for this? It ends up causing trouble if student is destroyed and restored, bc parents get added under both of those actions
  #  children.each{|child| child.add_parents if child.parents.count == 1}
  #end

  def self.next_id_number(school)
    (where(['school_id = ?', school]).maximum('id_number') || 0) + 1
  end

  def all_events(start, finish, include_assignments = false, child = nil)
    all_child_events(start, finish, include_assignments, child) + 
    Event.for_person(id, start, finish)
  end

  def all_child_events(start, finish, include_assignments, child)
    child ? child.all_events(start, finish, include_assignments) : []
  end

  def ensure_new_children
    children.any?{|c|c.new_record?}? [] : [Student.new, Student.new]
  end

  def existing_and_new_children
    (children + ensure_new_children).map do |k| 
      k.id_number= nil if k.new_record?
      k
    end
  end

  def fellow_parent_ids
    children.map(&:parent_ids).flatten
  end

  def has_invalid_children?
    ! children.all?{|child| child.valid? }
  end

  def may_view_family_events_for(invitable_id)
    id == invitable_id || fellow_parent_ids.include?(invitable_id)
  end

  def may_view_personal_events_for?(creator_id)
    super(creator_id) || child_ids.include?(creator_id)
  end

  def replacements(search, school)
    gender = authorization.login.match('_(.)*')[0]
    @students = school.students.where(["last_name LIKE ?", search])
    @students.delete_if{|s| children.member?(s) || s.parent_login_checked?(gender)}
  end

  def existing_child_attributes=(child_attributes)
    children.reject(&:new_record?).each do |child|
      attr = child_attributes[child.id.to_s]
      if attr
        child.attributes = attr
        children.delete(child) if child.full_name.blank?
        child.save
      else
        children.delete(child)
      end
    end
  end

  def new_child_attributes=(child_attributes)
    child_attributes.each do |attr|
      children.build(attr.merge(:school_id => school_id)) unless attr[:first_name].blank? && attr[:last_name].blank?
    end
  end

  def discussables
    %w(school parents)
  end

  def display_name
    title.nil?? full_name : title + ' ' + last_name
  end

  def replace_old_parent_of(kid, match)
    if @replacement = should_replace_parent_of(kid, match)
      match.parents.delete(@replacement)
      children.delete(kid)
      children << match
      Parent.destroy(@replacement)
      true
    else
      errors.add(:base, "Someone else has already logged on as #{gender} for #{kid.full_name}. Please contact the school to have someone connect you to #{kid.first_name} in the database.")
    end
  end

  def should_replace_parent_of(kid, match)
    login = (kid.first_name + kid.last_name).downcase + '_' + gender
    replacement = match.parents.includes(:authorization).where(['authorizations.login = ?', login]).first
    replacement && replacement.never_logged_in? ? replacement : false
  end

  def may_access_forum_for?(discussable)
    case discussable.klass
    when 'Section'
      children.any?{|c| c.sections.member?(discussable)}
    else
      discussables.include? discussable.klass
    end
  end

  def may_participate_in?(discussable)
    discussable.klass == 'parents'
  end

  def id_required?; false; end

  def section_ids
    child.section_ids
  end

  def which_parent
    case last_name
    when '_mother'
      'mother'
    when '_father'
      'father'
    end
  end

  def valid?(context = nil)
    context ||= (new_record? ? :create : :update)
    errors.delete(:children) unless super(context)
    errors.empty?
  end

  protected

    def get_matches_for(kid)
      school.students.where(['first_name = ? AND last_name = ? AND grade = ?', kid.first_name, kid.last_name, kid.grade])
    end

    def new_children_added_correctly
      children.select{|child| child.new_record? }.each do |kid|
        matches = get_matches_for(kid)
        case matches.length
        when 0
          errors.add(:base, "I can't find #{kid.full_name} in the school database. If you spelled the name right, the school must have it wrong. In that case, delete it for now and let the school know they need to fix it.")
        when 1
          replace_old_parent_of(kid, matches[0])
        else
          if match = matches.detect{|m| m.id_number == kid.id_number}
            replace_old_parent_of(kid, match)
          else
            errors.add(:base, "There are #{matches.length} students in the school with the same info that you entered for #{kid.full_name}. If you know #{kid.first_name}'s id number, that should narrow it down. Otherwise, delete that name for now - you can add it once you find out what the id number is, or ask the school to do it for you.")
          end
        end
      end
  end

end

