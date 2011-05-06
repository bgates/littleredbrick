require 'active_model'
class Gradebook
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  validate :check_scores
  after_validation :reset_grades

  attr_reader :section, :grades, :assignments, :start, :section_grades, :changed_grades, :milestones, :range_grades

  def initialize(section, params = {})
    @section = section
    @assignments = @section.assignments.limit(5).order(:position).includes(:grades)
    filter_assignments(params)                            
    @start = @assignments.empty?? 0 : @assignments.first.position
    @grades, @milestones, @range_grades = Hash.new([]), Hash.new([]), Hash.new([])
    @section_grades = @assignments.collect{|a| a.grades}.flatten
  end

  def last_marking_period
    MarkingPeriod.find_by_track_id_and_reported_grade_id(section.track_id, 
                                        assignments.last.reported_grade_id)
  end

  def mark_invalid(bad_grades)
    bad_grades ||= []
    section_grades.each do |g| 
      g.errors.add(:score, 'invalid') if bad_grades.include?(g.id)
    end
  end

  def month_and_year
    return [Date.today.year, Date.today.mon] if assignments.empty?
    if assignments.last.date_due
      [assignments.last.date_due.year, assignments.last.date_due.mon]
    else
      date = assignments.last.grades.map(&:date_due).max
      [date.year, date.mon]
    end
  end

  def set_grades
    group_grades = section_grades.group_by(&:rollbook_entry_id)
    @section.rollbook_entries.each{|rbe| @grades[rbe.student_id] = group_grades[rbe.id] || []}
    @grades
  end

  def set_milestones
    return [] if @assignments.empty?
    marking_period = @assignments.last.reported_grade_id
    milestones = @section.milestones.find_all_by_reported_grade_id(marking_period).group_by(&:rollbook_entry_id)
    @section.rollbook_entries.each do |rbe|
      m = milestones[rbe.id][0]
      @milestones[rbe.student_id] = m.grade
    end
    @milestones
  end

  def set_range
    grades.each do |id, range|
      earned, possible = 0, 0
      range.each do |r|
        if r.graded?
          earned += r.score.to_f
          possible += @assignments.detect{|a| a.id == r.assignment_id}.point_value
        end
      end
      @range_grades[id] = possible == 0? '-' : 100.0*earned/possible
    end
    @range_grades
  end

  def spans_marking_periods?
    assignments.map(&:reported_grade_id).uniq.length > 1 
  end

  def update(grades = [])
    grades.delete_if {|key, value| unchanged(key, value)}
    @changed_grades = Grade.update(grades.keys, grades.values)
  end

  protected

    def check_scores
      unless @changed_grades.inject(true) {|memo, grade| grade.valid? && memo }
        errors.add(:base, 'some grades are invalid')
      end
    end

    def filter_assignments(params)
      conditions = case  
        when params[:start] then ['position >= ?', params[:start]] 
        when params[:marking_period] then ['reported_grade_id = ?', params[:marking_period]] 
        when params[:date] then ['date_due >= ?', params[:date]] 
        else nil
      end
      @assignments = @assignments.where(conditions) if conditions 
    end

    def reset_grades
      @section_grades.reject! {|grade| @changed_grades.any?{|changed| changed.id == grade.id}}
      (@section_grades ||= []).concat(@changed_grades)
      set_grades
    end

    def unchanged(key, value)
      section_grades.any? {|grade| grade.id.to_s == key && grade.score == value[:score]}
  end
end

