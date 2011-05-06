class EventsController < ApplicationController
  before_filter :login_required, :set_user_for_events
  layout :by_user
  include AssignmentPreparation
  #TODO: daily view should tell which track mp is beginning/ending for
  def index
    @year, @month = params[:year].to_i, params[:month].to_i
    if params[:day]
      @first = @last = Date.civil(@year, @month, params[:day].to_i)
    else
      @first = Date.civil(@year, @month, 1) #- 6 I'll need a full day to get calendar helper to display links to events from next/previous months
      @last = Date.civil(@year, @month, -1) #+ 6
    end
    @events = @user.all_events(@first, @last, true, @student)
    @ev, @assignments_and_grades = @events.partition{|e|e.is_a?(Event)}
    @academic_events, @nonacademic_events = @ev.partition{|e|e.invitable_type == 'Section'}
    @nonacademic_events.reject!{|e|e.id.nil?}
    render :action => "day" and return if params[:day]
  end

  def show

  end

  def edit

  end

  def assignment
    @assignment = Assignment.find(params[:assignment_id], :include => [:section, :grades])
    @section = @assignment.section
    set_assignment_variables
    @assignment.date_due = @assignment.grades.detect{|g| g.id == params[:grade].to_i}.date_due if params[:grade]
    @event = @assignment.clone #to let secondary nav work
    respond_to do |format|
      format.html{render :template => 'gradebook/assignments/show'}
    end
  end

  def new
    @event = Event.new(:date => Date.tomorrow)
  end

  def create #TODO: how to make family event?
    invite_id, type = set_invitables
    @event = Event.new((params[:event]).merge(:invitable_id => invite_id, :invitable_type => type, :creator_id => current_user.id))
    if @event.save
      flash[:notice] = "<h2>Good News</h2>The event has been added to your calendar"
      redirect_to calendar_url(:year => @event.year, :month => @event.month)
    else
      render :action => "new"
    end
  end

  def destroy
    flash[:notice] = "<h2>Good News</h2>The event #{@event.name} was removed" if @event.destroy
    respond_to do |format|
      format.html{redirect_to calendar_url(:year => @event.year, :month => @event.month)}
      format.js{render :update do |page|
          page.redirect_to calendar_url(:year => @event.year, :month => @event.month)
      end}
    end
  end

  def update
    id, type = set_invitables
    if @event.update_attributes((params[:event]).merge(:invitable_id => id, :invitable_type => type))
      flash[:notice] = "<h2>Good News</h2>The event #{@event.name} was updated successfully"
      redirect_to calendar_url(:year => @event.year, :month => @event.month)
    else
      @event.date = Date.today
      render :action => "edit"
    end
  end

  protected
  def authorized?
    @event = Event.find(params[:id]) if params[:id]
    case action_name
    when 'edit', 'update', 'destroy'
      @event.creator_id == current_user.id
    when 'show'
      @event.viewable_by?(current_user) || @event.creator_id == current_user.id
    else true
    end
  end

  def set_user_for_events
    if params[:student_id] && !current_user.is_a?(Student)
      @user = @school.users.find(params[:student_id])
    else
      @user = current_user
    end
    @sections =
    case @user.class.to_s
    when 'Student', 'Teacher'
      @user.sections
    when 'Parent'
      @student.sections
    else []
    end
  end

  def set_invitables
    if current_user.is_a?(Student) || params[:audience] == 'User'
      [current_user.id, 'User']
    elsif params[:audience].to_i == 0
      [@school.id, params[:audience]]
    else
      [params[:audience], 'Section']
    end
  end
end

