class Term::StagingController < Term::TermController
  before_filter :login_required, :select_user
  layout :initial_or_by_user

  def show
    @sections = find_sections.sort_by(&:time)
    set_subject_and_department if params[:subject]
  end

  def create
    @new_student = params[:id] ? @school.students.find(params[:id]) : @school.students.find_by_full_name(params[:search])
    @section = Section.find(params[:section]).includes([:subject, :teacher, :students])
    respond_to do |wants|
      wants.html do
        if @new_student && @section.students << @new_student
          flash[:notice] = "<h2>Good News</h2>#{@new_student.first_name} has been enrolled in #{@section.teacher.display_name}'s #{@section.name} class for next term."
        else
          flash[:error] = "<h2>Bad News</h2>There was a problem."
        end
        redirect_to term_staging_path(@term, :student => params[:student], :teacher => params[:teacher], :subject => params[:subject])
      end
      wants.js do
        @section.students << @new_student
        @students = @section.rollbook_entries.includes(:student)
        @student = @school.students.find(params[:student]) if params[:student]
      end
    end
  end

  def destroy
    @section = Section.find(params[:section])
    if @student = @section.students.find_by_full_name(params[:name])
      @section.unenroll(@student)
      flash[:notice] = "<h2>Good News</h2>#{@student.full_name} has been unenrolled from next term&#39;s #{@section.name} class."
    else
      flash[:error] = "<h2>Bad News</h2>No student named '#{params[:name]}' is enrolled in that #{@section.name} section."
    end
    redirect_to term_staging_path(@term, :student => params[:student], :teacher => params[:teacher], :subject => params[:subject])
  end

  def search
    @students = Student.search(@school.id, params[:section], params[:search].split.first)
    respond_to do |wants|
      wants.html{@student = Student.new; render :action => 'new', :controller => 'people/students'}
      wants.js{render :action => 'search_results', :layout => false}
    end
  end
private
  def authorized?
    if params[:student]
      (@student = @school.students.find_by_id(params[:student])) && current_user.is_a?(Staffer)
    elsif params[:subject]
      current_user.is_a?(Staffer)
    elsif params[:teacher]
      (@teacher = @school.teachers.find(params[:teacher])) && (current_user.is_a?(Staffer) || current_user.id == params[:teacher])
    else
      action_name == 'show' #no param given to students & parents, so they hit here
    end
  end

  def find_sections
    if @student
      if session[:initial]
        @student.sections.includes([:teacher, :subject, {:rollbook_entries => :student}])
      else
        @student.future_sections.includes([:teacher, :subject, {:rollbook_entries => :student}])#that's gotta change
      end
    elsif @teacher
      Section.where(['current = ? AND teacher_id = ?', !session[:initial].nil?, @teacher.id]).includes([:teacher, :subject, {:rollbook_entries => :student}])
    else
      Section.where(['subject_id = ? AND current = ?', params[:subject], !session[:initial].nil?]).includes([:teacher, {:subject => :department}, {:rollbook_entries => :student}])
    end
  end

  def set_subject_and_department
    if @sections.empty?
      @subject = Subject.find(params[:subject], :include => :department)
      @department = @subject.department
      #@department, @subject = Department.new(:name => 'No Department'), Subject.new(:name => 'No Subject')
    else
      @department, @subject = @sections.first.subject.department, @sections.first.subject
    end
  end

  def select_user
    return if @student || @teacher || params[:subject]
    case current_user.class.to_s
    when 'Student'
      @student = current_user
    when 'Parent'
      @student = current_user.children.find(session[:child])
    when 'Teacher'
      @teacher = current_user
    end
  end
end

