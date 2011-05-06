class People::TeachersController < ApplicationController
  before_filter :login_required
  before_filter :find_teacher, :except => [:index, :new, :create]
  layout :initial_or_by_user

  def index
    @term = params[:term].nil?? 0:1
    @low_period, @high_period = @school.terms[@term].low_period, @school.terms[@term].high_period
    @teachers = @school.teachers
    @sections = Section.where(['teacher_id IN (?) AND current = ?', @teachers.collect(&:id), params[:term].blank?]).includes(:subject).group_by(&:teacher_id)
    @prepped_for_assignments = session[:initial].nil? || !@sections.empty? || @school.departments.length != 0
  end

  def show
    @sections = @teacher.sections.where(['sections.current = ?', params[:term].blank?]).includes([{:assignments => :grades}, {:rollbook_entries => :milestones}, :subject])
    prepare_section_data 
  end

  def edit
    #TODO: harmonize this, admin/edit, parent/edit, teacher/edit, student/edit wrt reset msg
  end

  def update
    if @teacher.update_attributes(params[:teacher])
      flash[:notice] = "<h2>Good News</h2><p>#{@teacher.display_name}&#39;s account details have been updated.</p>"
      redirect_to teacher_path(@teacher)
    else
      render :action => "edit"
    end
  end

  def logins
    @logins = Login.scoped_by_user_id(@teacher.id).paginate :per_page => 10, :page => params[:page], :order => 'created_at desc'
  end

  def new
    @teacher = Teacher.new
  end

  def create
    @teacher = @school.teachers.create(params[:teacher])
    if @teacher.valid?
      redirect_to edit_teaching_load_url(@teacher), :notice => msg
    else
      render :action => "new"
    end
  end

  def destroy
    if @teacher.id == current_user.id
      flash[:error] = "<h2>You Can't Do That</h2>You are not allowed to delete yourself from the system."
      return_path = teacher_url(@teacher)
    else
      if @teacher.destroy
        flash[:notice] = "<h2>Good News</h2>#{@teacher.display_name} was removed from the system. All of that teacher's classes have been destroyed as well."
        return_path = teachers_url
      else
        flash[:error] = "<h2>Bad News</h2>Something went wrong, and #{@teacher.display_name} was not deleted."
        return_path = teacher_url(@teacher)
      end
    end
    respond_to do |format|
      format.html {redirect_to return_path}
      format.js{render :update do |page|
          page.redirect_to return_path
      end}
    end
  end
private

  def find_teacher
    @teacher = @school.teachers.find(params[:id])
  end

end
