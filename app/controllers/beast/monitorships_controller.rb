class Beast::MonitorshipsController < BeastController
  respond_to :html, :js
  cache_sweeper :monitorships_sweeper, :only => [:create, :destroy]

  def create
    @monitorship = current_user.monitorships.find_or_initialize_by_topic_id(params[:topic_id])
    @monitorship.update_attribute :active, true
    respond_with do |format|
      format.html { redirect_to forum_topic_path(@discussable, params[:forum_id], params[:topic_id]) }
    end
  end

  def destroy
    current_user.monitorships.deactivate(params[:topic_id])
    respond_with do |format|
      format.html { redirect_to forum_topic_path(@discussable, params[:forum_id], params[:topic_id]) }
    end
  end

  protected
  def authorized?
    @discussable.forums.detect{|f| f.id == params[:forum_id].to_i} &&
    current_user.may_access_forum_for?(@discussable)
  end
end
