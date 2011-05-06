class FrontPageController < ApplicationController
  before_filter :login_required
  layout :initial_or_by_user

  def home
    render :action => "setup" and return if current_user.admin? && setup_required?
    set_initial_msg
    case current_user.class.to_s
    when 'Student'
      @student = current_user
      setup_student
      render :action => "student"
    when 'Teacher', 'Staffer'
      setup_staff
      if session[:admin] || current_user.class.to_s == 'Staffer'
        render :action => "administrator", :layout => 'staffer'
      else
        @sections = current_user.sections.includes(:rollbook_entries => :milestones)
        teacher_initial_msg
        prepare_section_data unless @sections.empty?
        render :action => "teacher"
      end
    when 'Parent'
      setup_student
      check_absences
      render :action => "parent"
    when 'Superuser'
      redirect_to forums_path('help') and return
    end
  end

  def admin
    redirect_to home_url and return unless current_user.admin?
    render :layout => 'staffer'
  end

protected
=begin
  def absence_notice
    absences = Absence.parent_notice(@absences, @student.sections)
    absences.each{|k,v| absences[k] = absence_to_sentence(v)}
    if absences[:unexcused_days].blank? && absences[:unexcused_periods].empty?
      unless absences[:excused_days].blank? && absences[:excused_periods].blank?
        flash[:notice] = "<h2>#{@student.first_name} had the following excused absences#{since_last_time}</h2><p><ul><li>#{absences[:excused_days]}</li><li>#{absences[:excused_periods]}</li></ul></p>"
      end
    else
      flash[:error] = "<h2>#{@student.first_name} had the following attendance problems#{since_last_time}</h2><p><ul><li>#{absences[:unexcused_days]}</li><li>#{absences[:unexcused_periods]}</li>"
      unless absences[:excused_days].blank? && absences[:excused_periods].blank?
        flash[:error] += "</ul>#{@student.first_name} also had the following excused absences:<ul><li>#{absences[:excused_days]}</li><li>#{absences[:excused_periods]}</li>}"
      end
      flash[:error] += "</ul></p>"
    end
  end

  def absence_to_sentence(absences)
    absences.map do |code, n|
      pluralize @school.absence_codes(false)[code], n
    end.to_sentence
  end
=end
  def check_absences
    @date = current_user.logins.last ? current_user.logins.last.created_at : Date.today - 365
    @absences = @student.absences.where(["date > ?", @date]).includes(:section).sort_by{|a| [a.date, a.section.time]} #.group_by(&:date)
    #absence_notice
  end

  def set_topics_and_posts
    @topics = current_user.monitored_topics
    @posts = current_user.recent_posts_of_interest.reject{|p| @topics.map(&:id).include?(p.topic_id)}.sort_by(&:created_at).reverse[0,5-@topics.length] || []
  end
  
  def setup_student
    @rbes = @student.rollbook_entries.where(['sections.current = true']).includes([:milestones, {:section => [:teacher, :subject]}]).sort_by{|rbe| rbe.section.time}
    @mp = @rbes.empty?? MarkingPeriod.new(:position => 1) : @rbes.first.section.current_marking_period
    @ungraded = Grade.ungraded(@rbes)
    @events = @student.all_events(Date.today, Date.today + 7)
    set_topics_and_posts
  end

  def setup_required?
    if params[:setup]
      @school.mark_as_setup!
      session[:initial] = nil
    end
    return false unless @school.has_not_been_setup?
    @students = @school.students.count
    @teachers = @school.teachers.includes(:sections)
    @teachers_with_classes = @teachers.reject{|teacher| teacher.sections.empty?}.length
    @terms = @school.terms
    @staffers = @school.staffers.count - @teachers.length
    @subjects = Subject.where(['department_id IN (?)', @school.department_ids]).count
    @full = true #this is a hack to get #content to be full-width
    @all_enrolled = @teachers.all?{|t| t.all_sections_enrolled? } && @teachers_with_classes > 0
    setup_msg unless session[:initial]
    session[:initial] = true
  end

  def set_initial_msg
    if params[:setup]
      flash.now[:notice] = msg(:initial)
    elsif current_user.logins.count == 1 && session[:first_time].nil?
      flash.now[:notice] = msg(:welcome)
      session[:first_time] = true
    end
  end

  def setup_msg
    flash.now[:notice] = msg(:setup)
  end
    
  def setup_staff
    @events = current_user.all_events(Date.today, Date.today + 7)
    set_topics_and_posts
  end

  def since_last_time
    ' since your last login' unless session[:first_time]
  end
  
  def teacher_initial_msg
    if session[:first_time]
      flash[:notice] += msg(:teacher_initial)
      session[:first_time] = false
    end
  end
end
