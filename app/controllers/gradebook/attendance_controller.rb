class Gradebook::AttendanceController < ApplicationController
  before_filter :login_required, :set_date
  layout :by_user

  def edit
    @start = @date - @date.wday + 1
    @finish = @start + 4
    @sections = @teacher.sections.all(:include => :subject)
  end

  def show
    @start = @date - @date.wday - 6
    @finish = @start + 11
  end

  def update
    @section.date = @date
    @section.update_attributes(params[:section])
    flash[:notice] = "<h2>Good News</h2><p>The attendance record for #{@date.to_date.strftime("%A, %B %d")}  has been updated.</p>"
    redirect_to params[:chart] ? seating_chart_section_attendance_path(@section, :date => @date) : edit_section_attendance_path(@section, :date => @date)
  end
  
private
   
  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}, {:rollbook_entries => [:student, :absences]}])
    @teacher = @section.teacher
    current_user == @teacher || (action_name == 'show' && @section.belongs_to?(@school) && current_user.admin?)
  end

  def set_date
    @date = params[:date] ? params[:date].to_date : Date.today
  end
end
