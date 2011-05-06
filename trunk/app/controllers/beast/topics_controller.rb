class Beast::TopicsController < BeastController
  before_filter :find_forum_and_topic, :except => [:index, :show]
  before_filter :login_required, :except => :index
  caches_formatted_page :rss, :show
  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def new
    @topic, @post = Topic.new, Post.new
  end

  def show
    @forum = @discussable.forums.find(params[:forum_id], :include => [:topics => {:posts => :user}], :conditions => ['topics.id = ?', params[:id]])
    @topic = @forum.topics.first
    @voices = @topic.posts.collect{|p|p.user}.uniq
    @monitoring = current_user.monitorships.monitoring?(@topic)
    respond_to do |format|
      format.html do
        # keep track of when we last viewed this topic for activity indicators
        (session[:topics] ||= {})[@topic.id] = Time.now.utc if logged_in?
        # authors of topics don't get counted towards total hits - they do now, just not redirects to the page
        @topic.hit! unless flash[:ignore] #@topic.user_id == current_user.id
        @posts = Post.paginate_for_topic(params[:id], params[:page], 
                                         @discussable)
        @post = Post.new
      end
      format.xml do
        render :xml => @topic.to_xml
      end
      format.rss do
        @posts = @topic.posts.order('created_at desc').limit(25)
        render :action => 'show', :layout => false
      end
    end
  end

  def create
    @topic = @forum.topics.prep(current_user, @discussable, params)
    if @topic.save
      respond_to do |format|
        format.html { redirect_to forum_topic_path(@discussable, @forum, @topic) }
        format.xml  { head :created, :location => forum_topic_url(@discussable, @forum, @topic, :format => :xml) }
      end
    else
      @post = @topic.posts.first
      render 'new'
    end
  end

  def update
    @topic.attributes = params[:topic]
    @topic.assign_protected(current_user, @forum, params)
    if @topic.save
      respond_to do |format|
        format.html { redirect_to forum_topic_path(@discussable, @topic.forum_id, @topic) }
        format.xml  { head 200 }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @topic.destroy
    flash[:notice] = "Topic '{title}' was deleted."[:topic_deleted_message, @topic.title]
    respond_to do |format|
      format.html { redirect_to forum_path(@discussable, @forum) }
      format.xml  { head 200 }
      format.js {render :update do |page|
        page.redirect_to forum_path(@discussable, @forum)
      end}
    end
  end

  protected

    def find_forum_and_topic
      case action_name
      when 'edit', 'update'
        @forums, @forum = @discussable.forums, @discussable.forums.detect{|f|f.id == params[:forum_id].to_i}
      else
        @forum = @discussable.forums.find(params[:forum_id])
      end
      @topic = @forum.topics.find(params[:id]) if params[:id]
    end

    def authorized?
      case action_name
      when 'edit', 'update', 'destroy'
        @topic.editable_by?(current_user)
      when 'new', 'create'
        current_user.may_access_forum_for?(@discussable) &&
        (@forum.open || current_user.moderator_of?(@forum))
      when 'show'
        current_user.may_access_forum_for?(@discussable)
      end
    end
end

