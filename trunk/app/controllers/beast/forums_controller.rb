class Beast::ForumsController < BeastController
  skip_filter :login_required
  before_filter :find_group_and_user
  before_filter :find_forums, :only => [:edit, :update, :new]
  before_filter :login_required

  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def index
    if @discussable
      @forums = @discussable.forums.includes(:posts)
      @voices = @forums.map(&:user_ids).flatten.uniq.length
    else
      @school = School.find(@school.id) #most actions don't require anything besides school_id
      render :action => "personal"
    end
  end

  def show
    @forum = @discussable.forums.find(params[:id], :include => :moderators)
    # keep track of when we last viewed this forum for activity 
    (session[:forums] ||= {})[@forum.id] = Time.now.utc if logged_in?
    @topics = Topic.paginate_for_forum(@forum, params[:page])
  end

  def new
    @positions = @forums.collect(&:position)
    @positions.push((@positions.max || 0)+ 1)
  end

  def create
    @forum = current_user.owned_forums.create(params[:forum].merge({:discussable_type => @discussable.klass, :discussable_id => @discussable.id}))
    if @forum.valid? 
      @forum.insert_at(params[:forum][:position]) if params[:forum][:position] != @forum.position.to_s
      redirect_to forums_path(@discussable), :notice => msg
    else
      @forums = @discussable.forums
      render "new" 
    end
  end

  def edit
    @positions = @forums.collect(&:position)
  end

  def update
    @forum.update_attributes!(params[:forum].except(:position))
    @forum.insert_at(params[:forum][:position].to_i) unless @forum.position == params[:forum][:position].to_i
    redirect_to forums_path(@discussable) 
  end

  def destroy
    @forum = @discussable.forums.find(params[:id])
    @forum.destroy
    respond_to do |format|
      format.html { redirect_to forums_path(@discussable), :notice => msg }
      format.js {render :update do |page| page.redirect_to forums_path(@discussable, :notice => msg) end }
    end
  end

  protected

    def find_group_and_user
      @user = (params[:user_id] && !(current_user.is_a?Student))? @school.students.find(params[:user_id]) : current_user
      @sections = @user.sections.sort_by(&:time) if (@user.is_a?(Student) || @user.is_a?(Teacher))
      @sections = @student.sections.sort_by(&:time) if @user.is_a?(Parent)
    end

    def find_forums
      @forums = @discussable.forums
      @forum = params[:id] ? @discussable.forums.detect{|f| f.id == params[:id].to_i} : Forum.new
    end

  def authorized?
    session[:forums] ||= {}
    case action_name
    when 'edit', 'update', 'destroy'
      current_user.owns?(@forum)
    when 'new', 'create'
      current_user.may_create_forum_for?(@discussable)
    when 'index', 'show'
      @discussable.nil? || current_user.may_access_forum_for?(@discussable)
    end
  end

end

