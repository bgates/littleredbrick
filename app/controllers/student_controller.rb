class StudentController < ApplicationController
  before_filter :login_required
  before_filter :find_section, :except => :index
  layout 'student'
  include AssignmentPreparation

  def index
    @rbes = @student.rollbook_entries.where(['sections.current = true']).includes([{:grades => :assignment}, :milestones, {:section => [:teacher, :subject]}]).sort_by{|rbe| rbe.section.time}
    @sections, @progression = @rbes.collect{|r| r.section},{}
    prepare_section_data
    @rbes.each do |r|
      mp_grades = r.grades.select{|g| g.assignment.reported_grade_id == r.section.reported_grade_id}
      @progression[r.id] = r.grade_progression(mp_grades)
    end
  end

  def show
    @teacher = @section.teacher
    @marks = Milestone.order(@rbe.milestones.includes(:reported_grade))
    @sections = @student.sections
    rg_id = @marking_periods.detect{|mp| mp.position == @mp_position}.reported_grade_id
    @marking_period = @rbe.milestones.detect{|m| m.reported_grade_id == rg_id}
    @grades = @rbe.grades.within_a_week
    @graded, @ungraded = @grades.partition{|g| g.graded?}
    @mp_grades = @rbe.grades.select{|g| g.assignment.reported_grade_id == rg_id}
    @progression = @rbe.grade_progression(@mp_grades)
    @categorized_performance = @rbe.categorized_performance(@mp_grades)
    @posts = @section.posts.recent
  end

  def assignments
    conditions, array = set_assignment_conditions
    rbe = @student.rollbook_entries.find_by_section_id(@section)
    @grades = rbe.grades.where([conditions, *array]).includes(:assignment).sort_by(&:due)
    @section.reported_grade_id = @grades.empty? ? @section.current_marking_period.reported_grade_id : @grades.last.assignment.reported_grade_id
  end

  def assignment
    @assignment = @section.assignments.find(params[:assignment_id]).joins("INNER JOIN grades ON grades.assignment_id = assignments.id AND grades.rollbook_entry_id = #{@rbe.id}").select("assignments.*, grades.score AS score, grades.date_due AS individual_date ")
    @mp_position = @assignment.marking_period_number
    @category_points = @section.assignments.category_points(@assignment.category, @assignment.reported_grade_id)
    @mp_points = @section.assignments.marking_period_points(@assignment.reported_grade_id)
    positions = (@assignment.position - 2..@assignment.position + 2)
    @assignments = @section.assignments.where(['position IN (?)', positions]).order(:position)
  end

private

  def authorized?
    case current_user.class.to_s
    when 'Student'
      @student = current_user
    when 'Parent'
      @student #= current_user.children.find(session[:child])
    else
      false
    end
  end

  def find_section
    @section = @student.sections.find(params[:section_id], :include => [:teacher, :subject])
    prepare_section_data unless action_name == 'assignment'
    @rbe = @student.rollbook_entries.find_by_section_id(@section)
  end
end

