class Catalog::DepartmentsController < ApplicationController
  before_filter :login_required
  before_filter :find_department, :only => [:update, :destroy]
  layout :initial_or_by_user

  def create
    @department = @school.departments.create(params[:department])
    if @department.valid?
      respond_to do |wants|
        wants.html { redirect_to departments_path, :notice => msg }
        wants.js do
          render :update do |page|
            page.insert_html :bottom, 'catalog', 
                            :partial => 'department', :object => @department
            page.hide('department_form')
          end 
        end
      end
    else
      respond_to do |wants|
        @subjects = @department.subjects
        wants.html { render 'new' }
      end
    end
  end

  def destroy
    if @department.destroy
      respond_to do |wants|
        wants.html { redirect_to departments_path, :notice => msg }
        wants.js { render :update do |page|
                    page.remove(@department)
                  end }
      end
    else
      respond_to do |wants|
        wants.html { redirect_to departments_path, 
                                 :flash => { :error => msg(:error) }}
        wants.js #send error
      end
    end
  end

  def edit #sections makes enrollment less expensive sql
    @department = @school.departments.find(params[:id], 
                                           :include => :subjects)
    @subjects = @department.subjects
  end

  def index 
    @departments = @school.departments.includes(:subjects => :sections)
  end

  def new
    @department = Department.dummy
    @subjects = @department.subjects
    if request.xhr?
      render :update do |page|
        page.insert_html :after, 'catalog', :partial => 'department_form'
      end
    end
  end

  def update
    @prev_count = @department.subjects.length
    @department.update_attributes(params[:department])
    if @department.valid?
      redirect_to department_subjects_path(@department), :notice => msg
    else
      @subjects = @department.subjects
      render :action => "edit"
    end
  end
protected

    def find_department
      @department = @school.departments.find(params[:id], :include => :subjects)
    end

end
