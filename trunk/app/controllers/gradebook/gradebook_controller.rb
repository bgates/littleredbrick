class Gradebook::GradebookController < ApplicationController
  before_filter :login_required
  before_filter :setup
  after_filter  :set_back, :only => :show
  
  layout :by_user
#TODO: The gradebook should have an option to sort assignments by due date.
  def show
    setup_more
    @gradebook.mark_invalid(flash[:bad_grades])
  end
  
  def sort
    @students = @section.students.for_sorting
    return if request.get?
    @section.sort_by(@students, params)
    respond_to do |format|
      format.html{
        redirect_to section_gradebook_path(@section), :notice => msg(:sort)
      }
      format.js {render :nothing => true}
    end
  end

  def update
    unless params[:grade] && !params[:grade].empty?
      redirect_to section_gradebook_path(@section), 
                  :flash => { :error => msg(:error)} and return
    end
    @gradebook.update(params[:grade])
    if @gradebook.valid?
      redirect_to section_gradebook_path(@section, :start => params[:start]), :notice => msg 
    else
      flash.now[:error] = msg(:now)
      setup_more
      render :action => "show"
    end
  end
  
private

  def authorized?
    @teacher = current_user
    @teacher.is_a?(Teacher) && @section = @teacher.sections.find_by_id(params[:section_id], :include => [:subject, {:rollbook_entries => :student}])
  end

  def setup
    @sections, @students, @gradebook = @teacher.sections, @section.rollbook_entries.sort_by(&:position).map(&:student), Gradebook.new(@section, params)
    @assignments, @start, @all_assignments = @gradebook.assignments, @gradebook.start, @section.assignments.order(:position)
    @year, @month = @gradebook.month_and_year
  end

  def setup_more
    @grades, @milestones, @range_grades = @gradebook.set_grades, @gradebook.set_milestones, @gradebook.set_range
    if @gradebook.spans_marking_periods?
      @marking_period = @gradebook.last_marking_period 
    end
  end

end
