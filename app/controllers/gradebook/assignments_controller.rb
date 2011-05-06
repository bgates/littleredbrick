class Gradebook::AssignmentsController < ApplicationController
  before_filter :login_required
  before_filter :add_category_to_params, :only => [:create, :update]
  before_filter :find_assignment, :only => [:destroy, :edit, :update]
  layout :by_user
  include AssignmentPreparation

  def create
    @assignment = @section.assignments.create(params[:assignment])
    if @assignment.valid?
      redirect_to section_gradebook_path(@section), :notice => msg
    else
      if params[:assignment][:new_grades]
        @grades = @assignment.grades.sort_by{|g| g.rollbook_entry.position}
      end
      find_categories_and_marking_periods
      render :action => "new"
    end
  end

  def destroy
    @assignment.destroy
    flash[:notice] = msg
    respond_to do |format|
      format.html{redirect_to section_gradebook_path(@section)}
      format.js{render :update do |page|
          page.redirect_to section_gradebook_path(@section)
      end}
    end
  end

  def edit
    if @assignment.date_due.nil? || params[:due] == 'individual'
      @grades = @assignment.grades.includes(:rollbook_entry => :student)
    end
    @mp = @assignment.reported_grade_id
    find_categories_and_marking_periods
  end

  def index
    conditions, array = set_assignment_conditions
    @assignments = @section.assignments.where([conditions, *array]).includes(:grades).order('position')
    @high = @section.assignments.maximum(:point_value)
    set_marking_period
  end

  def new
    @assignment = @section.assignments.build
    @mp = @section.current_marking_period.reported_grade_id
    find_categories_and_marking_periods
    set_grades_with_due_dates if params[:due] == 'individual'
  end

  def performance
    conditions, array = set_assignment_conditions
    @assignments = @section.assignments.where([conditions, *array]).includes(:grades)
    @students = @section.rollbook_entries.includes(:student).sort_by(&:position)
    @high = @section.assignments.maximum(:point_value)
  end

  def show
    @assignment = @section.assignments.find(params[:id], :include => :grades)
    respond_to do |format|
      format.html { 
        set_assignment_variables
        @assignments = @section.assignments.near(@assignment)
      }
      format.any { send_file @assignment.attachment.path }
    end
  end

  def update 
    @assignment.individual_due_dates = false unless params[:assignment][:grades]
    if @assignment.update_attributes(params[:assignment])
      redirect_to section_gradebook_path(@section), :notice => msg
    else
      find_categories_and_marking_periods
      set_grades_new_due_dates if params[:assignment][:grades]
      render :action => "edit"
    end
  end

private

  def add_category_to_params
    params[:assignment].merge!(:category => params[:category]) if params[:category].present?
  end

  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}])
    @teacher = @section.teacher
    current_user == @teacher || user_may_see_as_admin? || 
    (action_name == 'show' && current_user.is_a?(Teacher)) #should only be teacher who shares a student w @teacher, but the check for that is needlessly expensive
  end

  def find_categories_and_marking_periods
    @marking_periods = @section.track.marking_periods.includes(:reported_grade)
    @categories = @section.assignments.categories + %w(Classwork Homework Quiz Test Report)
  end

  def find_assignment
    @assignment = @section.assignments.find(params[:id])
  end

  def set_grades_new_due_dates
    @grades = @assignment.grades.includes(:rollbook_entry => :student)
    @grades.each do |g|
      g.date_due = params[:assignment][:grades][g.id.to_s][:date_due]
      g.date_assigned = params[:assignment][:date_assigned]
      g.valid?
    end
  end

  def set_grades_with_due_dates
    @grades = @section.rollbook_entries.includes(:student).map{|rbe| rbe.grades.build(:date_due => Date.today + 1)}
  end

  def set_marking_period
    @mp = params[:mp].blank?? @section.current_marking_period.position : 
          params[:mp].is_a?(Array)? nil : 
          params[:mp].to_i
  end

  def user_may_see_as_admin?
    current_user.admin? && %w(index show).include?(action_name) && 
    @section.belongs_to?(@school) 
  end
end
