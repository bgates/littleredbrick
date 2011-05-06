class Beast::UsersController < BeastController

  def index
    @users = @discussable.members(params[:page])
    @user_count = @discussable.membership
    @posts = @discussable.posts.recent_by_user
  end

  def show
    params.merge!({:reader_id => params[:id]})
    @user = User.find(params[:id])
    @recent_posts = @user.posts.recent(10, @discussable)
    set_forum_activity_counts
    @discussable_posts = @discussable.posts.count_for_user(@user)
    @moderated_forums = @user.forums.find_all_for_discussable(@discussable).with_moderatorships
  end

protected
  def authorized?
    current_user.may_access_forum_for?(@discussable)&&
    (current_user.is_a?(Staffer) || %w(show index).include?(action_name))
  end

end

