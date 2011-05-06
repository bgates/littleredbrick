class Gradebook::EnrollmentController < ApplicationController
  before_filter :login_required
  skip_filter :set_back, :only => ['new', 'search', 'create']
  layout :initial_or_by_user
  include AssignmentPreparation

  def new

  end

  def create
    if params[:names]
      if params[:names].blank?
        flash.now[:error] = msg(:oops)
        render "new"
      else
        set_multiple_student_flash
        return_from_create and return
      end
    elsif @student = @school.students.find_by_id(params[:id])
      @section.enroll(@student)
      flash[:notice] = msg
      respond_to do |wants|
        wants.html { return_from_create }
        wants.js {render :update do |page|
          page.redirect_to new_section_enrollment_url(@section)
        end}
      end
    else
      respond_to do |wants|
        wants.html { flash.now[:error] = msg(:now);render 'new' }
        wants.js{render :update do |page|
          page.redirect_to new_section_enrollment_path(@section)
        end}
      end
    end
  end

  def search
    @students = Student.search(@school.id, @section.id, params[:search], params[:grade]) - @section.students
    respond_to do |wants|
      wants.html{render 'new'}
      wants.js{render 'search_results', :layout => false}
    end
  end

  def destroy
    @student = @section.students.find(params[:id])
    @section.unenroll(@student)
    flash[:notice] = msg
    respond_to do |format|
      format.html {redirect_to section_path(@section)}
      format.js {render :update do |page|
          page.redirect_to params[:gradebook] ? section_gradebook_path(@section) : section_path(@section)
      end}
    end
  end

private

  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}])
    @teacher = @section.teacher
    current_user.is_a?(Staffer) || (%w(show marks assignments).include?(action_name) && generally_authorized?)
  end

  def generally_authorized?
    current_user == @teacher || (current_user.admin? && @section.belongs_to?(@school))
  end

  def msg_for(list)
    list.length > 5 ? "#{list.length} students" : list.to_sentence
  end

  def process_names(names)
    names.split(/[\r]?\n/).map{|name| name.split(',').reverse.join(' ').chomp.strip.sub(/\s+/, ' ')}.reject{|name| name.empty? || name =~ /^\s+$/}
  end

  def return_from_create
    redirect_back_or_default(new_section_enrollment_path(@section))
  end

  def set_multiple_student_flash                            #TODO- helper
    enrollees = @section.bulk_enroll(params[:names], @school)
    if enrollees.empty?
      flash[:error] = "<h2>Bad News</h2>The students you entered were either already enrolled in the class or not in the school database. To add students to the database, click <a href='#{new_student_path}'>here</a>."
    elsif enrollees != process_names(params[:names])
      missing = process_names(params[:names]) - enrollees
      missing_msg = msg_for(missing)
      flash[:error] = "<h2>Bad News</h2>Some of the student names you entered were either already enrolled in the class or not in the school database. The following students were enrolled: #{enrollees.to_sentence}. If you need to add students to the database, click <a href='#{new_student_path}'>here</a>"
    else
      enroll_msg = msg_for(enrollees)
      flash[:notice] = "<h2>Good News</h2>#{enroll_msg} #{enrollees.length > 1 ? 'have' : 'has'} been enrolled."
      flash[:notice] += ' To start creating assignments for the class, click the "Gradebook" link.' if current_user == @teacher
    end
  end

end

