class Gradebook::SeatingChartController < ApplicationController
  before_filter :login_required
  layout :by_user

  def new
    @rbes = @rbes.sort_by{rand} if params[:order]
  end

  def create
    @seating_chart = SeatingChart.new(@section, params[:seat])
    @seating_chart.save
    render :action => "new" and return unless @seating_chart.valid?
    redirect_to section_path(@section), :notice => msg
  end

  def show
    redirect_to new_section_seating_chart_path(@section) and return if @section.has_no_seating_chart?
  end

  def edit

  end

  def update

  end

private

  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}, {:rollbook_entries => :student}])
    @teacher = @section.teacher
    @rbes = @section.rollbook_entries
    current_user == @teacher || (action_name == 'show' && @section.belongs_to?(@school) && current_user.admin?)
  end

end
