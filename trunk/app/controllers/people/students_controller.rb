class People::StudentsController < ApplicationController
  before_filter :login_required
  before_filter :find_student, :except => [:index, :new, :create, :show, :attendance]
  layout :initial_or_by_user

  def index
    @condition = params[:term].blank?
    @term = @condition ? 0 : 1
    @low_period, @high_period = @school.terms[@term].low_period, @school.terms[@term].high_period
    @students = @school.students.includes(:rollbook_entries => {:section => :subject})
  end

  def show
    @student = @school.students.find(params[:id], :include => [:logins, :absences, {:parents => :logins}])
    @rbes = @student.rollbook_entries.where(['sections.current = true']).includes([{:grades => :assignment}, :milestones, {:section => [:teacher, :subject]}]).sort_by{|rbe| rbe.section.time}
    @sections, @progression = @rbes.collect{|r| r.section},{}
    prepare_section_data
    rpg = MarkingPeriod.find_by_track_id_and_position(@rbes[0].section.track_id, @mp_position).reported_grade_id unless @rbes.empty?
    @rbes.each do |r|
      r.section.reported_grade_id = rpg
      mp_grades = r.grades.select{|g| g.assignment.reported_grade_id == r.section.reported_grade_id}
      @progression[r.id] = r.grade_progression(mp_grades)
    end
  end

  def edit
    @school = School.find(@school.id)
  end

  def update
    if @student.update_attributes(params[:student])
      redirect_to student_path(@student), :notice => msg
    else
      render :action => "edit"
    end
  end

  def logins

  end

  def new
    @student = Student.new
    @school = School.find(@school)
  end

  def create
    @student = @school.students.create(params[:student])
    if @student.valid?
      redirect_to students_path, :notice => msg
    else
      render :action => "new"
    end
  end

  def destroy
    if @student.destroy
      flash[:notice] = msg
      respond_to do |format|
        format.html {redirect_to students_path}
        format.js {render :update do |page|
            page.redirect_to students_path
        end}
      end
    else
      redirect_to student_path(@student), :flash => { :error => msg(:error)}
    end
  end

  def sections
    @section = Section.includes(:rollbook_entries).where(['rollbook_entries.student_id = ? AND sections.current = ?', @student.id, params[:term].blank?]).first
    prepare_section_data
    rbes = @student.rollbook_entries.map(&:section_id)
    @sections = Section.where(['sections.id IN (?) AND milestones.reported_grade_id = ?', rbes, @section.reported_grade_id]).includes([:assignments, :teacher, {:rollbook_entries => :milestones}, :subject]).sort_by{|s|s.time}
    @sections.each{|s| s.reported_grade_id = @section.reported_grade_id}
  end

  def marks
    @rbes = @student.rollbook_entries.includes([{:section => [:teacher, :subject]}, {:milestones => :reported_grade}])
  end

private

  def authorized?
    current_user.is_a?(Teacher) || current_user.is_a?(Staffer)
  end

  def find_student
    @student = @school.students.find(params[:id])
  end
end

