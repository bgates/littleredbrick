class TeachingLoadController < ApplicationController
  before_filter :login_required, :find_teacher
  layout :initial_or_by_user
  helper :teaching_load

  def new
    redirect_to edit_teaching_load_url(@teacher, 
                              :term => params[:term]) and return unless find_sections.empty?
    set_section_form
  end

  def create
    @teacher.update_attributes(params[:teacher])
    redirect_to return_from_create_path, :notice => msg
  end

  def edit
    respond_to do |wants|
      wants.html { set_section_form }
      wants.js do
        prep_for_js
        render params[:length].blank?? 'set_departments' : 'edit'
      end
    end
  end

  def update
    @teacher.update_attributes(params[:teacher])
    redirect_to return_from_update_path, :notice => msg
  end

  def destroy
    @section = Section.find_by_id_and_teacher_id(params[:section_id], @teacher.id)
    if request.xhr?
      @section.destroy if @section
      respond_to do |wants|
        wants.html {redirect_to edit_teaching_load_path(@teacher)}#redir include n and term
        wants.js
      end
    end
  end

protected

  def authorized?
    super  || (params[:teacher_id] = nil && current_user.is_a?(Teacher))
  end
                    
  def find_sections
    @sections ||= @teacher.sections.anytime.where(['current = ?', params[:term].blank?])
  end

  def find_teacher
    @teacher = @school.teachers.find(params[:teacher_id] || current_user)  
  end

  def return_from_create_path
    if current_user.admin?
      teachers_path(:term => params[:term])
    elsif params[:term].blank?
      sections_path
    else           
      term_staging_path(@school.terms.last, :teacher_id => @teacher)
    end
  end

  def return_from_update_path
    if session[:initial] 
      teachers_path
    elsif current_user == @teacher 
      sections_path 
    else
      teacher_path(@teacher)
    end
  end

  def set_section_form
    @departments = @school.departments
    @teacher_departments  = params[:department].blank?? 
      @teacher.departments : 
      @departments.select{|d| params[:department].values.map(&:to_i).include?(d.id)}
    @department_subjects = @teacher.department_subjects
    set_term_and_tracks
    @sections = set_sections.sort_by{|s|s.time || 0}
    1.upto(@n){|n| @sections << Section.new} if @n > 0
    @n += 1
    session[:return_to] ||= request.fullpath
  end

  def set_sections #this needs to be changed in case...you know, there can be new/create here
    if find_sections.empty?
      if @low_period.nil?
        6.times{|n| @teacher.sections.build }
      else
        (@low_period..@high_period).map do |n|
          @teacher.sections.build(:time => n) 
        end
      end
    else
      @sections
    end
  end

  def set_term_and_tracks
    @n = params[:length].to_i
    @term = params[:term].blank?? 0 : 1
    @low_period, @high_period = @school.terms[@term].low_period, @school.terms[@term].high_period
    @tracks = @school.terms[@term].tracks
  end

  def prep_for_js
    @department_subjects = params[:department].blank?? @teacher.department_subjects : Subject.find_all_by_department_id(params[:department].values.map(&:to_i))
    set_term_and_tracks
  end

end
