class Beast::PostsController < BeastController
  skip_filter :login_required
  before_filter :find_post,      :only => [:edit, :update, :destroy]
  before_filter :login_required
  respond_to :html, :xml, :rss
  caches_formatted_page :rss, :index, :monitored
  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def index
    @posts = @discussable.posts.restrict_by(params)
    set_forum_activity_counts
    find_users
    respond_with @posts
  end

  def search
    #TODO: make search immune to tags...should be as easy as adding an attribute called "search_html" and creating it by stripping tags before saving, then searching by it
    @posts = @discussable.posts.search(params[:q], params[:page])
    set_forum_activity_counts
    find_users
    render_posts_or_xml :index
  end

  def monitored
    @posts = @discussable.posts.monitored(params[:reader_id], params[:page])
    set_forum_activity_counts
    find_users
    render_posts_or_xml
  end

  def create
    topic = Topic.find_by_id_and_forum_id(params[:topic_id],params[:forum_id], :include => :forum)
    @post  = topic.posts.build(params[:post])
    @post.set_restricted_values(current_user, @discussable)
    flash[:ignore] = true
    if @post.save
      respond_to do |format|
        format.html do
          redirect_to return_path
        end
        format.xml { head :created, :location => forum_topic_post_url(@discussable, params[:forum_id], params[:topic_id], @post, :format => :xml) }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to forum_topic_path(@discussable, params[:forum_id], params[:topic_id], :page => params[:page] || '1', :anchor => 'reply-form'), :flash => { :error => msg(:error) }
        end
        format.xml { render :xml => @post.errors.to_xml, :status => 400 }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @post.attributes = params[:post]
    flash[:error] = 'An error occurred' unless @post.save
    flash[:ignore] = true
    respond_to do |format|
      format.html do
        redirect_to return_path
      end
      format.js
      format.xml { head 200 }
    end
  end

  def destroy
    @post.destroy
    path, flash[:notice] = return_from_destroy_path, msg
    flash[:ignore] = true
    respond_to do |format|
      format.html do
        redirect_to path, :notice => msg
      end
      format.js do
        render :update do |page|
          page.redirect_to path
        end
      end
      format.xml { head 200 }
    end
  end

  protected
    def authorized?
      case action_name
      when 'index', 'monitored'
        current_user.may_access_forum_for?(@discussable)
      when 'new', 'create'
        current_user.may_access_forum_for?(@discussable)
      when 'edit', 'update', 'destroy'
        @post.editable_by?(current_user)
      when 'search'
        current_user.may_access_forum_for?(@discussable) || !@discussable
      end
    end

    def find_post
      @post = Post.find_by_id_and_topic_id_and_forum_id(params[:id], params[:topic_id], params[:forum_id]) || raise(ActiveRecord::RecordNotFound)
    end

    def find_users
      @users = User.authors_of(@posts)
      @user = User.find(params[:reader_id]) if params[:reader_id]
    end

    def render_posts_or_xml(template_name = action_name)
      respond_to do |format|
        format.html { render :action => template_name }
        format.rss  { render :action => template_name, :layout => false }
        format.xml  { render :xml => @posts.to_xml }
      end
    end

    def return_from_destroy_path
      [:q, :all].each do |val|
        return posts_path(@discussable, val => params[val]) if params[val]
      end
      if @post.topic.frozen?
        forum_path(@discussable, params[:forum_id]) 
      else
        forum_topic_path(@discussable, params[:forum_id], params[:topic_id], :page => params[:page]).sub(/\?\z/,'')
      end
    end

    def return_path
      forum_topic_path(@discussable, params[:forum_id], params[:topic_id], :page => params[:page] || '1', :anchor => @post.dom_id) 
    end
end

