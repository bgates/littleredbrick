class SearchController < ApplicationController
  layout :by_user

  def index
    @school = School.find(@school)
    @departments = @school.departments
    @low, @hi = @school.current_term.low_period, @school.current_term.high_period
    search if params[:commit]
  end

private
#TODO: search by current grade; search for teachers, find a route (where can this be accessed? /search?)
  def search
    condition_string, includes, condition_array = [], [], []
    if params[:grade]
      condition_string << 'users.grade IN (?)'
      condition_array << params[:grade]
    end
    if params[:department]
      condition_string << 'departments.id IN (?)'
      includes << {:rollbook_entries => {:section => [:teacher, {:subject => :department}]}}
      condition_array << params[:department]
    end
    if params[:period]
      condition_string << 'sections.time IN (?)'
      includes << {:rollbook_entries => {:section => :teacher}} if includes.empty?
      condition_array << params[:period]
    end
    conditions = [condition_string.join(' AND ')] + condition_array
    @students = @school.students.where(conditions).includes(includes)
  end
end
