module Beast::PostsHelper

  def class_for(post)
    post.user == @posts.first.user ? 'threadauthor fn' : 'fn'
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p @post.errors.full_messages.to_sentence.humanize
    when 'destroy'
      p "Post was deleted."
    end
  end

  def name_if_nonunique(post)
    if params[:reader_id].blank? 
      "<br/>#{reader_link(@discussable, post.user, 
        :class => class_for(post))} #{admin_status(post, post.forum)}".html_safe
    end
  end

  def nav_suffix
    if @user
      [readers_link(@discussable), reader_link(@discussable, @user), 
      (action_name == 'index' ? 'Posts' : 'Monitored Posts')]
    else
      case action_name 
      when 'search'
        posts = params[:q] ? "Search for '#{truncate(params[:q], 
                              :length => 10)}'" : 'All'
        [link_to('Posts', posts_path(@discussable), 
          :title => "Click to see every post in the #{@discussable.name}
                     forums"), posts]
      when 'edit'
        'Edit Post'
      when 'new'
        'New Post'
      else
        if @forum
          [forum_link(@discussable, @forum, @forum.name), 'Posts']
        else
          'Posts'
        end
      end
    end

  end

  def post_links(post)
    span forum_link(@discussable, post.forum_id, 
                    post.forum_name, post.forum_name) + 
         arrow + topic_link(@discussable, post.forum_id, 
                            post.topic_id, post.topic_title) + 
         name_if_nonunique(post) +
         span(pluralize(number_with_delimiter(@counts[post.user_id]),
                        'post'), :class => 'posts'), :class => 'fn'
  end

  def search_form
    if %w(search index).include?(action_name) 
      li(form_tag(search_posts_path(@discussable), :method => :get) + 
         text_field_tag('q', params[:q], :id => 'search_box',:size => 15) +
         "</form>".html_safe, :id => 'forum_search')
    end
  end

  def search_posts_title
    (params[:q].blank? ? 'All Posts' : "Searching for"[] + " '#{h params[:q]}'").tap do |title|
      title << " Monitored " if action_name == 'monitored'
      title << " "+'by {user}'[:by_user,h(@user.display_name)] if params[:reader_id]
      title << " "+'in {forum} Forum'[:in_forum,h(Forum.find(params[:forum_id]).name)] if params[:forum_id]
      #title << " | #{@discussable.name.titleize} Discussions"
    end
  end

  def secondary_nav
    breadcrumbs(discussable_front, discussable_link(@discussable), nav_suffix) + search_form
  end

  def title
    "#{@page_h1} | #{@discussable} Discussions"
  end
end
