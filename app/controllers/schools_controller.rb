class SchoolsController < ApplicationController
  skip_filter :domain_finder, :except => [:show, :edit, :update]
  before_filter :login_required, :except => [:new, :create, :search]

  layout :by_user

  def new
    #redirect_to home_path and return unless request.subdomains[0] == 'www'
    @school, @user = School.new, User.new
    render :action => "personal", :layout => false and return if params[:account] == 'personal'
    render :layout => false
  end

  def create #note I changed domain from 'littleredbrick.com' to "domain.littleredbrick"
    @school = School.new(params[:school])
    @user = @school.initial_user(params)
    @school.teacher_limit = 1 unless params[:group]
    @user.signup = true
    if @school.valid? && @user.valid?
      @school.contact = @user
      @school.save
      session[:erste] = msg
      redirect_to  "http://#{@school.domain_name}.littleredbrick.com#{dev_port}/login"
    else
      @school.errors.delete(:teachers)
      @school.errors.delete(:staffers)
      [:login, :password, :password_confirmation].each do |attr|
        @user.authorization[attr] = params[:user][:authorization][attr]
      end
      [:login, :password].each{|attr|@user.authorization.errors.add(attr, "can't be blank") if params[:user][:authorization][attr].blank?}
      render :action => "new", :layout => false
    end
  end

  def update
    domain = @school.domain_name
    @school.update_attributes(params[:school])
    if @school.valid?
      flash[:notice] = msg
      redirect_to domain == @school.domain_name ? school_url : "http://#{@school.domain_name}.littleredbrick.com" and return
    end
    render :action => "edit"
  end

  def show
    @last_term = @school.terms.includes([:reported_grades, {:tracks => :marking_periods}]).first
    @teachers = @school.teachers
    @sections = @school.sections
    @enrollment = RollbookEntry.where(['section_id IN (?)', @sections.collect(&:id)]).count
    @events = @school.upcoming_events
    @students = @school.students
  end

  def search
    if request.post?
      school_name = params[:school].sub(/\s*/, '')
      @schools = School.where(['(LOWER(name)) LIKE (?)', "#{school_name.downcase}%"])
      first, last = params[:name].split
      @users = User.where(['first_name = ? AND last_name = ?', first, last])
      @school = set_school
      if @school
        session[:erste] = msg
        redirect_to  "http://#{@school.domain_name}.littleredbrick.com/login" and return
      elsif @schools.length > 1  
        flash.now[:error] = "<h2>Problem</h2>There are multiple schools named #{school_name}."
      else
        flash.now[:error] = "<h2>Problem</h2>We can&#8217;t find a school named #{school_name} or a user named #{params[:name]}. You can search for a different spelling, ask someone else at your school for help, or email us at #{self.class.helpers.mail_to 'support@littleredbrick.com', 'support@littleredbrick.com', :encode => :hex}"
      end
    else
      @schools = [:none]
    end
    render :layout => false
  end
  
  protected
    def authorized?
      @school = School.find(@school.id)
      super
    end

    def dev_port
      ":3000" if Rails.env == 'development'
    end

    def set_school
      match = @schools.select{|s| @users.map(&:school_id).include?(s.id)}
      if match.length == 1
        @school = match.first
      elsif @schools.length > 1
        narrowed_list = @schools.select{|s| s.name == params[:school]}
        if narrowed_list.length == 1
          @school = narrowed_list.first
        end
      elsif @schools.length == 1
        @school = @schools.first
      elsif @users.length == 1
        @school = @users.first.school
      end
    end
end
