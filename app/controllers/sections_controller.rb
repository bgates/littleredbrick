class SectionsController < ApplicationController
  before_filter :login_required#, :except => 'index'
  before_filter :set_sections, :except => 'index'
  skip_filter :set_back, :only => ['edit', 'update']
  layout :initial_or_by_user

  def index
    redirect_to teachers_url and return unless current_user.is_a?(Teacher)
    @teacher = current_user
    @sections = @teacher.sections.includes([:reported_grades, :assignments, :track, :subject, {:rollbook_entries => :milestones}])
    if @sections.empty?
      redirect_to new_teaching_load_path(@teacher), :notice => msg and return
    end
    prepare_section_data
  end
  #TODO: in some circumstances, links to assignments/index don't have right marking period
  #if current_mp > 1 and looking at mp 1, the link under "number of assignments" goes to mp1 not mp1&mp2 etc - in fact that link has mp[]=1&mp[]=2 etc up to the params[:mp], not up to the current mp - this is a prepare_section_data problem
  def show
    @posts = ForumActivity.for(@section)
    @students = @section.rollbook_entries.sort_by(&:position).map(&:student)
    @sections_of_class = Section.where(["subject_id = ? AND current = ?", @section.subject_id, @section.current]).count
    @subject, @department = @section.subject, @section.department
    prepare_section_data
    @recent_assignments = @section.assignments.last_graded(3)
    @class_posts = @section.posts.where(["posts.created_at > ?", Date.today - 7]).count
    flash.now[:notice] = "<p>To delete a student, click the <img src=\"/images/sub_16.png\" alt = 'Remove Student' title = 'Remove Student'/> symbol beside his name.</p>" if params[:unenroll]
  end

  def edit
    if params[:grade_scale]
      render :action => "edit_grade_scale" and return
    else
      @subjects = @section.department.subjects
      @teachers = @school.teachers
      @lo, @hi = @section.term.low_period, @section.term.high_period
    end
  end

  def update
    @section.update_attributes(params[:section])
    render :action => "edit_grade_scale" and return unless @section.errors[:grade_scale].empty?
    if params[:all_sections]
      @sections.each{|s| s.update_attribute(:grade_scale, @section.grade_scale) if s.subject_id == @section.subject_id && s != @section}
    end
    redirect_to section_url(@section), :notice => msg
  end

  def destroy
    @section.destroy
    redirect_to return_from_destroy, :notice => msg
  end

private
  def authorized?
    if params[:id]
      if action_name == 'show'
        @section = Section.find(params[:id], :include => [:teacher, :reported_grades, :assignments,  {:subject => :department}, {:rollbook_entries => [:grades, :milestones, :student]}])
      else
        @section = Section.find(params[:id], :include => :teacher)
      end
      @teacher = @section.teacher
    else
      @teacher = params[:teacher_id].nil?? current_user : @school.teachers.find(params[:teacher_id])
    end
    (current_user.is_a?(Teacher) && current_user.id == @teacher.id) || (current_user.admin? && @teacher.school_id == @school.id)
  end

  def return_from_destroy
    @teacher == current_user ? sections_path : teachers_path
  end

  def set_sections
    @sections = @teacher.sections
  end

end
