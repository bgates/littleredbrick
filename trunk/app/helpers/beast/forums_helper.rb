module Beast::ForumsHelper

  def and_classes_if_teacher
    ", as well as for each of your classes" if current_user.is_a?(Teacher)
  end

  def help_link
    if action_name == 'index' && @discussable
      link_to 'Help', '/help/discussions', :title => 'Click for an overview of how discussion groups work'
    else
      super
    end
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p("Your forum has been created. You have the ability to moderate " +
      "the forum, meaning you are able to edit or remove anything posted" +
      " within the forum, or add new discussion topics. Since you created" +
      " the forum, you are also allowed to assign other users to be" +
      " moderators. #{note_on_posting} Click on the forum name to add its" +
      " first discussion topic.")
    when 'destroy'
      p "The #{@forum.name} forum has been deleted."
    end
  end

  def new_examples_for(discussable)
    case discussable.klass
    when 'Section'
     "a class forum could be named 'extra credit' and have one topic for each extra credit assignment, or be named for a book read in class and have a topic for discussion of each chapter or major character."
    when 'school'
     "a school forum could be named 'sports' and have one topic for each team."
    when 'admin'
      "an administrative forum could be named 'staff policies' and have discussions for sick leave, professional development, or district announcements."
    when 'staff'
     "a staff forum could be named 'professional development' and have discussions for district policies on different training programs."
    when 'parents'
     "a parent forum could be named 'graduation requirements' and include topics like 'coursework', 'citizenship', etc."
    when 'teachers'
     "a teacher forum could be named 'union issues' and have discussions for union announcements, elections, etc."
    end
  end

  def note_on_posting
    if @forum.open 
      'Since you have created the forum as "open", anyone who can access ' +
      'the forum may add discussion topics.' 
    else
      ' Because you have set the forum to be "closed", only the people ' +
      'you choose to be moderators are allowed to add topics.'
    end
  end

  def post_data(post, discussable)
    if post.nil?
      '&nbsp;'.html_safe
    else
      page = (post.topic.posts_count / 25.0).ceil
      path = forum_topic_path(discussable, post.forum_id, post.topic_id, 
                              :page => page)
      link_to(post.created_at.strftime('%b %d'), path, 
              :title => "#{post.user.display_name}: #{truncate(post.body, :separator => ' ')}".html_safe)
    end
  end

  def post_stats(scope)
    discussable = controller.find_or_initialize_discussable(scope)
    posts = Post.where(['discussable_type = ? AND discussable_id = ?', discussable.type, discussable.id]).includes([:user, :topic])
    td(posts.count) + td(post_data(posts.last, discussable))
  end

  def recent_activity_indicator(forum)
    if logged_in? && forum.posts.length > 0 && forum.posts.last.created_at >  (session[:forums][forum.id] || last_active)
      image_tag "comment.gif", :class => "icon highlight", :title => 'This forum has had recent activity'[:recent_activity]
    else
      image_tag "comment.gif", :class => "icon grey", :title => 'No recent activity'[:no_recent_activity]
    end
  end

  def recent_topic_activity_indicator(topic)
    icon, color, locked = topic.locked ? ['lock', 'darkgrey', ", this topic is locked."[:comma_locked_topic]] : ['comment', '', '']
    if topic.replied_at >= (session[:topics][topic.id] || last_active)
      image_tag "#{icon}.gif", :class => "icon highlight", :title => "Recent activity"[]+"#{locked}"
    else
      image_tag "#{icon}.gif", :class => "icon grey #{color}", :title => "No recent activity"[]+"#{locked}"
    end
  end

  def secondary_nav
    return unless @discussable
    breadcrumbs discussable_front, secondary_nav_for_action
  end

  def secondary_nav_for_action
    if action_name == 'index'
      if @forums.empty?
        "#{@discussable.name.titleize} Forums"
      else
        secondary_search
      end
    else
      [discussable_link(@discussable), @page_h1]
    end
  end

  def secondary_search
    span(form_tag(search_posts_path(@discussable), :method => :get) + 
         label_tag('search_box',
                   "Search #{@discussable.name.titleize} Forums") +
         text_field_tag('q', params[:q], :id => 'search_box', :size => 15)+
         "</form>".html_safe, :id => 'forum_search') 
  end

  def title
    case action_name
    when 'index'
      "#{@discussable.name.titleize} Forums | Discussions"
    when 'edit', 'update'
      "Edit Forum | #{@discussable.name.titleize} Discussions"
    when 'show'
      "#{@page_h1} | #{@discussable.name.titleize} Discussions"
    when 'new', 'create'
      "#{@page_h1} | Discussions"
    end
  end

  def topic_title_link(topic, options = {})
    options.merge!(:title => 'Click to read all the posts on this topic')
    if topic.title =~ /^\[([^\]]{1,15})\]((\s+)\w+.*)/
      span($1, :class => 'flag')  +
      link_to($2.strip, forum_topic_path(@discussable, @forum, topic), 
              options)
    else
      link_to(topic.title, forum_topic_path(@discussable, @forum, topic),
              options)
    end
  end

end

