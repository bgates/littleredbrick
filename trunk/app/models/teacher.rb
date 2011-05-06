class Teacher < Staffer
  has_many              :sections, :order => :time, :include => :subject, :conditions => 'sections.current = true',
                        :dependent => :destroy do
    def anytime
      except(:where).where(['teacher_id = ?', proxy_owner.id])
    end
  end
  accepts_nested_attributes_for :sections
  has_many              :assignments, :through => :sections

  validate              :teacher_count, :on => :create #TODO: does validate on_create get bypassed w bulk creation through upload?
  attr_accessor :admin

  def all_sections_enrolled?
    sections.all?{|s| s.enrollment > 0 }
  end

  def departments
    subjects = Subject.find(sections.collect{|sec|sec.subject_id}.uniq)
    Department.find(subjects.collect{|s|s.department_id}.uniq, :include => :subjects)
  end

  def department_subjects
    departments.map(&:subjects).flatten 
  end

  def discussables
    %w(school teachers staff)
  end

  def may_create_forum_for?(discussable)
    sections.member?(discussable) || %w(school teachers).member?(discussable.klass) ||
    (admin? && %w(staff parents).member?(discussable.klass))
  end

  def may_access_forum_for?(discussable)
    case discussable.klass
    when 'Section'
      sections.member?(discussable)
    when 'Group'
      groups.member?(discussable)
    when 'help', 'school', 'staff', 'teachers', 'parents'
      true
    end
  end
  #call event repeatedly to use sql index
  def all_events(start, finish, include_assignments = false, student = nil)
    events = universal_events(start, finish, section_or_school_track)  +
    Event.for_sections(start, finish, section_ids) + 
    Event.for_staff(school_id, start, finish)  
    if include_assignments
      events += Assignment.for_sections(start, finish, section_ids)
      events += Grade.for_sections(start, finish, section_ids)
    end
    events.sort_by(&:date)
  end

  def teaches?(section)
    id && id == section.teacher_id
  end

  def make_admin
    roles << Role.find_or_create_by_title('admin') 
    self.admin = true
    self
  end

  def revoke_admin
    roles.delete(Role.find_by_title('admin'))
  end

  def can_act_as_admin?
    roles.detect{|r|r.title == 'admin'}
  end

  def admin?
    admin
  end

  def may_see?(item)
    case item
    when Section
      teaches?(item) || admin?
    when Teacher
      admin?
    end
  end

  protected
    def teacher_count
      if school && school.teacher_limit && !school.may_add_more_teachers?
        errors.add(:base, "You have reached the limit on the number of teachers you can create.")
        return false
      end
      return true
    end

end
