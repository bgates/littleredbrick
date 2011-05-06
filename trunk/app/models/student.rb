class Student < User
  has_many                :rollbook_entries, :dependent => :destroy
  has_many                :sections, :through => :rollbook_entries, :conditions => 'current = true'#, :order => :time
  has_many                :future_sections, :source => :section, :through => :rollbook_entries, :order => :time, :conditions => 'current = false'
  has_many                :grades, :through => :rollbook_entries
  has_many                :milestones, :through => :rollbook_entries
  has_many                :absences, :dependent => :destroy
  has_and_belongs_to_many :parents
  after_create            :add_parents
  #before_destroy          :delete_superfluous_parents

  alias :display_name :full_name

  def self.find_by_full_name(name)
    first, last = name.split
    find_by_first_name_and_last_name(first, last)
  end

  def self.find_by_last_first(name)
    last, first = name.split
    find_by_first_name_and_last_name(first, last)
  end

  def self.for_mark(mark)
    where(["milestones.reported_grade_id = ?", mark.id]).includes(:rollbook_entries => :milestones)
  end

  def self.for_sorting
    select('users.*, rollbook_entries.position AS position, rollbook_entries.id AS rbe_id')
  end

  def self.search(school_id, section, string, grade = nil)
    query = where(["school_id = ?", school_id])
    query = query.where(["(last_name ILIKE ? OR first_name ILIKE ? OR id_number = ?)",
                       "#{string}%","#{string}%", string.to_i])
    query = query.where(["grade IN (?)", grade]) if grade
    students = query.select("id, id_number, last_name, first_name, school_id, grade, type").order("last_name ASC")
    enrolled = RollbookEntry.enrolled_student_ids_for(section)
    students.delete_if{|student| enrolled.any?{|member| member.student_id == student.id}}
  end

  def academic_events(start, finish)
    Event.for_sections(start, finish, section_ids)
  end

  def all_events(start, finish, include_assignments = false, student = nil)
    (universal_events(start, finish, section_or_school_track) +
    academic_events(start, finish) +
    family_events(start, finish) +
    all_assignments(start, finish, include_assignments, section_ids)).sort_by{|event| event.date}
  end

  def all_assignments(start, finish, include_assignments, section_ids)
    if include_assignments
      Assignment.for_sections(start, finish, section_ids) +
      grades.for_sections(start, finish, section_ids)
    else
      []
    end
  end

  def assignments
    sections.collect{|s|s.assignments}.flatten
  end
  
  def destroy #TODO: this is a placeholder bc before_destroy 
              #doesnt' work with habtm in 3,0,3
    delete_superfluous_parents
    super
  end
  
  def discussables
    %w(school)
  end

  def family_events(start, finish)
    Event.for_family(parent_ids, start, finish)
  end

  def may_access_forum_for?(discussable)
    case discussable.klass
    when 'Section'
      sections.member?(discussable)
    when 'Group'
      groups.member?(discussable)
    else
      discussables.include? discussable.klass
    end
  end

  def may_view_family_events_for?(invitable_id)
    parent_ids.include?(invitable_id) 
  end

  def may_see?(section)
    sections.member?(section) #worried about this
  end

  def parent_login_checked?(gender)
    !parents.any? do |parent|
      gender = Regexp.new(gender)
      parent.login =~ gender && parent.never_logged_in?
    end
  end

  protected

    def add_parents
      next_id = Parent.next_id_number(school_id)
      %w(father mother).each_with_index do |parent, i|
        adult = school.parents.build(:first_name => login, 
                                     :last_name =>  "_#{parent}", 
                                     :id_number => next_id + i)
        default = "#{login}_#{parent}"
        adult.build_authorization(:login => default, :password => default, 
                                  :password_confirmation => default, 
                                  :school_id => school_id)
        parents << adult
      end
    end

    def delete_superfluous_parents
      parents.each do |parent|
        if parent.children(true).count == 1
          parent.destroy
        end
      end
    end
end

