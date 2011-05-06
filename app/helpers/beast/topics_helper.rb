module Beast::TopicsHelper

  def author_class(post)
    post.user == @posts.first.user ? 'threadauthor fn' : 'fn'
  end

  def is_locked?(topic)
    span "(#{'locked'[]})" if topic.locked?
  end

  def secondary_nav
    breadcrumbs discussable_front,
                discussable_link(@discussable), 
                forum_link(@discussable, @forum), @page_h1
  end

  def admin?
    current_user.moderator_of?(@forum) #or current_user == @section.teacher
  end

  def post_links(post) 
    reader_link(@discussable, post.user, :class => author_class(post)) +
    admin_status(post, @forum) +
    span(pluralize(number_with_delimiter(post.user.forum_activities.first.posts_count), 'post'), :class => 'posts')
  end

  def title
    "#{@page_h1} | #{@discussable.name.titleize} Discussions"
  end
end
