class AttendanceController < ApplicationController

  def index
    @students = @school.students.includes(:sections, :absences)
    @date = params[:date] ? params[:date].to_date : Date.today
    @low_period, @high_period = @school.current_term.low_period, @school.current_term.high_period
  end

  def show
    @student = @school.students.find(params[:id], :include => [:sections, :absences])
    #@student = @school.students.find(params[:id]).includes([{:rollbook_entries => [{:section => :subject}, :absences]}])
    @absences = @student.absences.group_by(&:section_id)
    @start, @finish = @sections.first.track.start, @sections.first.track.finish
    @month = params[:month] ? params[:month].to_i : Date.today.month
    @year = params[:year] ? params[:year].to_i : Date.today.year
  end

  def edit
    @codes = @school.absence_codes(false)
  end

  def update

  end
end
