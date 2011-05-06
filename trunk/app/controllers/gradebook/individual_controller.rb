class Gradebook::IndividualController < ApplicationController
  before_filter :login_required
  before_filter :find_rbe, :only => %w(attendance assignments show marks)
  layout :initial_or_by_user
  include AssignmentPreparation

  def show
    @student = @rbe.student
    find_marking_period
    rg_id = @marking_periods.detect{|mp| mp.position == @mp_position}.reported_grade_id
    @marking_period = @rbe.milestones.detect{|m| m.reported_grade_id == rg_id}
    @grades = @rbe.grades.select{|g| ((Date.today - 7)..(Date.today + 7)).include?(g.due)}.sort_by{|g|g.due} #.within_a_week does this - more sql?
    @graded, @ungraded = @grades.partition{|g| g.graded?}
    @mp_grades = @rbe.grades.select{|g| g.assignment.reported_grade_id == rg_id}
    @progression = @rbe.grade_progression(@mp_grades)
    @categorized_performance = @rbe.categorized_performance(@mp_grades)
    @posts = @section.posts.recent(3).where(['posts.user_id = ?', @student.id])
  end

  def assignments
    conditions, array = set_assignment_conditions
    @graded = @rbe.grades.where([conditions, *array]).includes(:assignment => :grades).sort_by{|grade| grade.assignment.position}
  end

  def marks
    @marks = @rbe.sort_milestones
  end

  def attendance
    @absences = @rbe.absences
    @start, @finish = @student.sections.first.track.start, @student.sections.first.track.finish
  end

private

  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}])
    @teacher = @section.teacher
    current_user.is_a?(Staffer) || (%w(show marks assignments).include?(action_name) && generally_authorized?)
  end

  def find_rbe
    @rbe = @section.rollbook_entries.with_all_info(params[:id])
    @student = @rbe.student
    @sections = @student.rollbook_entries.collect(&:section)
  end

  def generally_authorized?
    current_user == @teacher || (current_user.admin? && @section.belongs_to?(@school))
  end

  def msg_for(list)
    list.length > 5 ? "#{list.length} students" : list.to_sentence
  end

end

