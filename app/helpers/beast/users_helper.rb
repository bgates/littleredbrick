module Beast::UsersHelper

  def admin?(discussable)
    discussable.forums.any?{|forum| current_user.moderator_of?(forum)}
  end

  def nav_for_action
    if @user
      [readers_link(@discussable), @user.display_name]
    else
      'Members'
    end

  end

  def secondary_nav
    breadcrumbs discussable_front, discussable_link(@discussable), 
                nav_for_action
  end

  def he_or_you
    @user.id == current_user.id ? 'You' : @user.display_name
  end

  def conjugate_has
    @user.id == current_user.id ? 'have' : 'has'
  end

  def post_links(post)
    [forum_link(@discussable, post.forum_id, post.forum_name, 
                post.forum_name), 
     topic_link(@discussable, post.forum_id, post.topic_id, 
                post.topic_title)].join(arrow).html_safe + "<br/>".html_safe
  end

  def title
    "#{@page_h1} | #{@discussable.name.titleize} Discussions"
  end
end
