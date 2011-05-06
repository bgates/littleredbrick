class RollbookEntry < ActiveRecord::Base
  belongs_to                            :section, :counter_cache => :enrollment
  belongs_to                            :student
  has_many                              :milestones, :dependent => :delete_all
  has_many                              :grades, :dependent => :delete_all do
    def within_a_week
      includes(:assignment).where(["assignments.date_due IN (:date_range) OR grades.date_due IN (:date_range)", :date_range => ((Date.today - 7)..(Date.today + 7))]).sort_by{|g|g.due}
    end
  end
  has_many                              :absences
  acts_as_list                          :scope => :section
  validates_uniqueness_of               :student_id, :message => "A student can be enrolled in a class only one time", :scope => :section_id
  after_create                          :set_grades_and_milestones, :set_forum_activity
  delegate :first_name, :last_name, :last_first, :id_number, :to => :student
  delegate :teacher, :name, :time, :to => :section

  def self.bulk_grades_and_milestones_for(sections)
    rbes = where(['section_id IN (?)', sections.map{|s|s.id}]).includes([:grades, :milestones])
    grades, milestones = [], []
    term_grades = sections[0].term.reported_grades
    rbes.each do |rbe|
      section = sections.detect{|s| s.id == rbe.section_id}
      if rbe.milestones.empty?
        required_marks = section.reported_grades + term_grades
        required_marks.each{|m| milestones << Milestone.new(:reported_grade_id => m.id, :rollbook_entry_id => rbe.id)}
        ForumActivity.find_or_create_by_user_id_and_discussable_type_and_discussable_id(rbe.student_id, 'Section', rbe.section_id)
      end
      if rbe.grades.empty?
        section.assignments.each{|a| grades << Grade.new(:assignment_id => a.id, :rollbook_entry_id => rbe.id, :score => Grade::DEFAULT_SCORE)}
      end
    end
    Milestone.import milestones, :validate => false
    Grade.import grades, :validate => false unless grades.empty?
  end

  def self.with_all_info(id)
    where(['rollbook_entries.student_id = ?', id]).includes([{:student => {:rollbook_entries => {:section => :subject}}}, {:grades => {:assignment => :grades}}, :milestones]).first
  end

  def enrolled_student_ids_for(section)
    where(["section_id = ?", section]).select("student_id, section_id")
  end

  def categorized_performance(grades)
    category_hash = (grades.reject!{|g| !g.graded?} || grades).group_by{|g| g.assignment.category}
    category_hash.each do |category, grades|
      category_hash[category] = {:earned => grades.sum{|g| g.score.to_f}, :possible => grades.sum{|g| g.point_value}}
    end
  end#this isn't right

  def grade_for(assignments)
    @grade_for ||= (
    h = Hash.new(0)
    assignments.each do |a|
      if (g = a.grades.detect{|g| g.rollbook_entry_id == id}).graded?
        h[:earned] += g.score.to_f; h[:possible] += a.point_value.to_f
      end
    end
    h[:percent] = h[:possible] == 0 ? 'N/A' : 100.0* h[:earned] / h[:possible]
    h)
  end

  def grade_progression(grades)
    grades = grades.reject{|g| !g.graded?}.sort_by{|g| g.due}
    return [] if grades.empty?
    milestone = milestones.detect{|m| m.reported_grade_id == grades.last.assignment.reported_grade_id}
    return [] if milestone.possible == 0
    progression = [{:position => 'current', :grade => milestone.grade}]
    num, denom = milestone.earned, milestone.possible
    grades.reverse.each do |g|
      #if g.graded?
        num -= g.score.to_f
        denom -= g.point_value
        return progression if denom == 0
        progression.unshift({:position => grades.index(g), :grade => (100 * num / denom), :description => g.due.strftime("%b %d") })
      #end
    end
    progression
  end
  
  def sort_milestones(marks = nil)
    marks ||= milestones.includes(:reported_grade)
    sorted_reported_grades = ReportedGrade.sort(marks.map(&:reported_grade))
    marks.sort_by{ |m| sorted_reported_grades.index(m.reported_grade) }
  end
  protected

  def set_grades_and_milestones
    section.assignments.each{|assignment| assignment.default_grade_for(self)}
    Milestone.setup(section, self)
  end

  def set_forum_activity
    ForumActivity.create(:user_id => student_id, :discussable_type => 'Section',  :discussable_id => section_id)
  end

end
