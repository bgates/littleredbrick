class Catalog::SubjectsController < ApplicationController
  before_filter :login_required
  before_filter :find_department_and_subject, :except => [:index, :create, :new]
  before_filter :find_department, :only => [:create, :new]
  before_filter :find_section, :only => [:index, :show]
  layout :by_user

  def create
    @subject = @department.subjects.create(params[:subject])
    if @subject.valid?
      redirect_to department_subjects_url(@department), :notice => msg
    else
      render :action => "new"
    end
  end

  def destroy
    @subject.destroy
    respond_to do |format|
      format.js {render :update do |page|
        page.remove "#{@subject.id}"
      end}
      format.html do
        redirect_to department_subjects_url(@department), :notice => msg
      end
    end
  end

  def edit
    @departments = @school.departments
  end

  def index
    @departments = @school.departments 
    @department = @school.departments.with_teachers.find(params[:department_id])
  end

  def show
    @sections = @subject.sections.all_data
    @sections.sort_by{|s|s.enrollment} if params[:sort]
    prepare_section_data unless @sections.empty?
  end

  def update
    @subject.update_attributes(params[:subject])
    if @subject.valid?
      redirect_to department_subject_path(@subject.department_id, @subject),
                  :notice => msg
    else
      @departments = @school.departments
      render :action => "edit"
    end
  end

private

  def authorized?
    super  || (current_user.is_a?(Teacher) && %w(index show).include?(action_name))
  end

  def find_department_and_subject   
    @subject = Subject.with_department_and_school(params[:department_id],
                                                 @school.id).find(params[:id])
    @department = @subject.department if @subject
  end

  def find_department  
    @department = @school.departments.includes(:subjects).find(params[:department_id])
  end

  def find_section
    if params[:section_id]
      @section = current_user.sections.find(params[:section_id], :include => {:subject => :department})
      params[:subject_id] = @section.subject_id
      params[:department_id] = @section.department.id
    end
  end
end
