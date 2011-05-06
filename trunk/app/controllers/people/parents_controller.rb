class People::ParentsController < ApplicationController
  before_filter :login_required
  before_filter :find_student, :except => :index
  before_filter :find_parent, :except => [:index, :new, :create]
  layout :initial_or_by_user

  def index
    if params[:student_id]
      find_student
      @parents = @student.parents
      render :action => "student_index"
    else
      @parent_count = @school.parents.count
      @parents = @school.parents.paginate(:include => :children, :page => params[:page], :per_page => 15)
    end
  end

  def new
    @parent = Parent.new
  end

  def create
    if params[:parent_id]
      @parent = (params[:parent_id] == 'new') ? @school.parents.new(params[:parent]) : @school.parents.find(params[:parent_id])
    else
      @parents = @school.parents.find_all_by_first_name_and_last_name(params[:parent][:first_name], params[:parent][:last_name])
      @parent = @school.parents.new(params[:parent]) if @parents.empty?
    end
    if @parent && @parent.save
      @student.parents << @parent
      flash[:notice] = "<h2>Good News</h2>#{@parent.full_name} can log in using login and password <code>#{@parent.login}</code> to see information about #{@parent.children(true).map(&:full_name).to_sentence}."
      redirect_to student_path(@student)
    else
      @parent ||= Parent.new(params[:parent])
      @parent.errors.delete(:login) if @parent.errors[:login] =~ /is too short/
      render :action => "new"
    end
  end
  
  def show
    @children = @parent.children
    @posts = @parent.posts.limit(5).order('created_at DESC').includes([:topic, :forum])
    @logins = @parent.logins.paginate(:page => params[:page], :per_page => 15) unless @parent.never_logged_in?
  end

  def update
    if params[:replace] && params[:replace] != 'new'
      @new_parent = @school.parents.find(params[:replace])
      @student.parents << @new_parent
      @student.parents.delete(@parent)
      flash[:notice] = "<h2>Good News</h2>#{@new_parent.full_name} has replaced #{@parent.full_name}"
    elsif params[:parent]
      @parents = @school.parents.find_all_by_first_name_and_last_name(params[:parent][:first_name], params[:parent][:last_name])
      if @parents.empty? || @parents == [@parent] || (params[:replace] && params[:replace] == 'new')
        if @parent.update_attributes(params[:parent])
          flash[:notice] = "<h2>Good News</h2>Changes saved"
        end
      end
    end
    if flash[:notice]
      redirect_to student_path(@student)
    else
      render :action => "edit"
    end
  end

  def edit
  end

  def destroy
    if params[:remove]
      @student = @school.students.find(params[:remove])
      @parent.children.delete(@student)
      flash[:notice] = "<h2>Good News</h2>#{@parent.full_name} can no longer access information about #{@student.full_name}"
    else
      @parent.destroy
      flash[:notice] = "<h2>Good News</h2>#{@parent.full_name} has been deleted."
    end
    respond_to do |format|
      format.html{redirect_to student_path(@student)}
      format.js{render :update do |page|
          page.redirect_to student_path(@student)
      end}
    end
  end

protected

  def find_parent
    @parent = @student.parents.find(params[:id])
  end

  def find_student
    @student = @school.students.find(params[:student_id])
  end

  def authorized?
    current_user.is_a?(Teacher) || current_user.is_a?(Staffer)
  end
end
