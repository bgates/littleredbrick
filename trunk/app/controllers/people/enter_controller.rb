class People::EnterController < ApplicationController
  before_filter :login_required, :find_type
  layout :initial_or_by_user
  include AccountUploadHandler
  def multiple
  end

  def names
    return unless request.post?
    if params[:names].blank?
      flash.now[:error] = "Please enter at least one name." and return
    end
    names = params[:names].to_s.split(/\r*\n/)
    @new_people = names.map{|name| name=~/,/ ? User.new(:last_first => name) : User.new(:full_name => name)}.reject{|user| user.first_name.blank? && user.last_name.blank?}
    render :action => "details"
  end
  
  def details 
    if request.post?
      set_saveable_and_new
      if @saveable && should_not_add_more_accounts?
        flash[:notice] = msg(@saveable.all?{|u| u.has_default_login?})
        if params[:last]
          flash[:import] = {:type => @type, :number => @saveable.length} if flash[:pending_import]
          redirect_to home_url and return
        end
      else
        (@new_people || []).each do |u|
          u.note_wrong_login
        end
        flash[:substitutes] = @substitutes
      end
      flash.keep(:pending_import)
    end
    set_new_people
  end

protected

  def find_type
    @type = params[:id].sub(/^.*\//,'')
    @type = 'students' unless %w(teachers students administrators).include? @type
    @school = School.find(@school.id)
    @low, @hi = @school.low_grade, @school.high_grade
  end

  def new_people_all_saved?
    @new_people.empty? && (@substitutes).all?{|u| u.errors.empty? && u.authorization.errors.empty?} && @substitutes.each{|u| u.save(:validate => false); @saveable << u}
  end

  def set_new_people
    return unless @new_people.blank?
    if @type == 'teachers' && (@remaining = @school.teacher_limit - @school.teachers.length) < 8
      @new_people = Array.new(@remaining){|u| User.new}
    else
      @new_people = Array.new(8){|u| User.new}
    end
  end

  def should_not_add_more_accounts?
    teacher_limit_reached? || new_people_all_saved? 
  end

  def teacher_limit_reached?
    @type == 'teachers' && !@school.may_add_more_teachers?(true)
  end
end
