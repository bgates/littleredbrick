class Section < ActiveRecord::Base
  include SectionDiscussion
  include GradeScale
  belongs_to                 :teacher
  belongs_to                 :subject
  belongs_to                 :track
  has_many                   :absences
  has_many                   :assignments, :dependent => :destroy do
    def _last #Date.today is ok because the #detect call eliminates anything with nil date_due
      sort_by{|a| a.date_due || Date.today }.flatten.reverse.detect{|a| a.reported_grade_id == proxy_owner.reported_grade_id && a.due_recently? && a.graded?} || Assignment.new(:title => 'None assigned')
    end

    def current
      select{|a| a.reported_grade_id == proxy_owner.reported_grade_id}
    end

    def last_graded(n)
     current.select{|a| a.due_recently? && a.graded?}.sort{|a,b| b.date_due <=> a.date_due}[0..(n - 1)].reverse
    end

    def _next
      sort_by{|a| a.date_due || Date.today}.detect{|a| a.due_soon?} || Assignment.new(:title => 'None assigned') #TODO: this can't see assignments with individual due dates for each student (like class presentations where it gets staggered, though that's rare)
    end
  end
  has_many                   :events, :as => :invitable, :dependent => :destroy
  has_many                   :grades#, :through => :assignments
  has_many                   :milestones, :through => :rollbook_entries
  has_many                   :reported_grades, :as => :reportable,
                                               :dependent => :destroy
  has_many                   :rollbook_entries, :dependent => :destroy
  has_many                   :students, :through => :rollbook_entries,
                                        :order => 'rollbook_entries.position'
  validates_presence_of      :teacher_id, :message => "must be present"
  validates_presence_of      :track_id, :message => "must be present"
  validates_presence_of      :subject_id, :message => "must be present"
  attr_accessor              :reported_grade_id, :date
  delegate :term, :marking_periods, :to => :track
  delegate :department, :to => :subject

  def self.all_data
    where("sections.current = true").includes([:reported_grades, 
                                              { :assignments => :grades }, 
                                              :teacher, :track, 
                                              { :subject => :department }, 
                                        { :rollbook_entries => :milestones }]).sort_by{|s| [s.teacher.last_name,s.time.to_s]}
  end

  def absences=(abs)
    absences.find_all_by_date(date).each do |exist_abs|
      exist_abs.update_attributes(:code => abs.delete(exist_abs.student_id.to_s))
    end
    abs.each do |student_id, absence|
      next if absence.blank?
      rbe = rollbook_entries.detect{|rbe| rbe.student_id == student_id.to_i}
      absences.create(:student_id => rbe.student_id, :rollbook_entry_id => rbe.id, :code => absence, :date => date)
    end
  end
  
  def add_milestones(reported_grade)
    rollbook_entries.each{|rbe| rbe.milestones.create(:reported_grade_id => reported_grade, :earned => 0, :possible => 0)}
  end

  def average
    graded = grade_distribution.values.reject{|g| g.possible == 0}
    @average = graded.empty?? "<span title='No assignments graded for this marking period'>N/A</span>".html_safe : graded.sum(&:grade) / graded.size
  end

  def belongs_to?(school); subject.department.school_id == school.id; end

  def bulk_enroll(students, school)
    enrollees = []
    students.split(/[\r]?\n/).each do |name|
      processed_name = name.split(',').reverse.join(' ').chomp.strip.sub(/\s+/, ' ')
        student = school.students.find_by_full_name(processed_name)
      if student
        enrollees << processed_name if enroll(student)
      end
    end
    enrollees
  end

  def current_marking_period
    marking_periods.where(["start < ?", Date.today]).order("start DESC").first || 
    marking_periods.order("start ASC").first
  end

  def enroll(student)
    students << student unless students.include?(student) || student.nil?
  end

  def grade_distribution
    return @gr_dist if @gr_dist
    distribution = {}
    milestones_for_class.each do |milestone|
      key = rollbook_entries.detect{|r| r.id == milestone.rollbook_entry_id}.student_id
      distribution[key] = milestone
    end
    @gr_dist = distribution
  end

  def marks
    ReportedGrade.sort(reported_grades + term.reported_grades)
  end

  def sort_by(students, params)
    sorted_ids = sort_ids_by(students, params)
    rollbook_entries.each do |entry|
      entry.update_attributes(:position => sorted_ids.index(entry.id.to_s) + 1)
    end
  end

  def has_no_seating_chart?
    rollbook_entries.all?{|rbe| rbe.x.nil? && rbe.y.nil?}
  end

  def marks_by_student
    milestones.group_by do |milestone|
      rollbook_entries.detect do |rbe|
        rbe.id == milestone.rollbook_entry_id
      end.id
    end
  end

  def mps; self[:mps] ||= marking_periods.map(&:position); end

  def name
    subject.nil?? 'Prep' : subject.name
  end

  def name_and_time(and_period = true)
    time.nil?? name : and_period ? "#{name}(Period #{time})" : 
                                   "#{name}(#{time})"
  end

  def point_distribution
    return @pt_dist if @pt_dist
    distribution = {}
    assignments.current.group_by(&:category).each do |category, assignment_array|
      distribution[category] = assignment_array.sum(&:point_value)
    end
    @pt_dist = distribution
  end

  def time_and_name
    time.nil?? name : "Period #{time} #{name}"
  end

  def unenroll(student)
    rollbook_entries.find_by_student_id(student).destroy
  end

  protected

    def all_students_milestones
      rollbook_entries.map(&:milestones).flatten
    end

    def milestones_for_class
      rbe_ids = rollbook_entries.map(&:id)
      all_students_milestones.select do |m|
        m.reported_grade_id == reported_grade_id &&
        rbe_ids.include?(m.rollbook_entry_id)
      end
    end

    def sort_ids_by(students, params)
      if params[:student]
        list = []
        params[:student].map{|id, attr| list[attr['position'].to_i - 1] = id}
        list
      elsif params[:list]
        params[:list]
      else
        students.sort_by(&:last_name).map(&:rbe_id)
      end
    end

end
