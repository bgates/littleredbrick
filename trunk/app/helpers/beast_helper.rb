module BeastHelper

  def admin_status(post, forum)
    if post.user.is_a?(Teacher) or post.user.moderator_of?(forum)
      status = ''
      status += "#{'Moderator'[:moderator_title]} " if post.user.moderator_of?(forum)
      status += "#{'Teacher'[:administrator_title]}" if post.user.is_a?(Teacher)
      span status, :title => "#{post.user.display_name + ' may edit or remove any post or topic in this forum' if post.user.moderator_of?(forum)}", :class => "admin"
    end
  end

  def discussable_link(discussable)
    link_to "#{discussable.name.titleize} Forums", forums_path(discussable),
            :title => "Click to see all the #{discussable.name} forums"
  end

  def forum_link(discussable, forum, text = nil, title = nil, options = {})
    text ||= "#{forum.name} Forum"
    title ||= forum.name
    options.merge!(:title => "Click to see all the topics in the #{title} forum")
    link_to text, forum_path(discussable, forum), options
  end

  def discussable_front
    link_to "Discussions", personal_path, :title => "Click to see all of your discussion groups"
  end

  def footer
    footer = '&copy; 2011 Little<a href="http://www.littleredbrick.com" class="company">Red</a>Brick'
    footer += %(<p class="credit">#{'Forum based on'[:powered_by]} <a href="http://beast.caboo.se/">Beast</a> &copy;2009 <a href="http://www.workingwithrails.com/person/5337-josh-goebel" class="subtle">Josh Goebel</a> #{'and'[:and]} <a href="http://weblog.techno-weenie.net" class="subtle">Rick Olson</a></p>)
    footer.html_safe
  end

  def last_active
    session[:last_active] ||= Time.now.utc
  end

  def mark_of_the_beast
    'class="beast"'
  end

  def reader_link(discussable, user, options = {}, truncated = true)
    name = truncated ? truncate(user.display_name, :length => 15) : 
                       user.display_name
    link_to name, reader_path(discussable, user), 
            options.merge(:title => "Click to see every post #{user.display_name} has made in the #{discussable.name} forums")
  end

  def readers_link(discussable)
    link_to 'Members', readers_path(discussable), 
      :title => "Click to see how active different people have been in writing posts in the #{discussable.name} forums"
  end

  def show_all_posts?
    [:user_id, :topic_id, :all].all?{|value| params[value].blank? }
  end

  def topic_link(discussable, forum, topic, text)
    link_to text, forum_topic_path(discussable, forum, topic), 
            :title => 'Click to see all the posts on this topic'
  end

end
