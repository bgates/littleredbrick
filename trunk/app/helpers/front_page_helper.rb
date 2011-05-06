module FrontPageHelper
  include SetupHelper

  def discussable_for(topic)
    #top line is in case user is a teacher but also an admin...
    if topic.last_post.discussable_type == 'Section' 
      @sections ||= [Section.find(topic.last_post.discussable_id)]
      @sections.detect{|s| s.id == topic.last_post.discussable_id} 
    else
      school = School.new
      school.type = topic.last_post.discussable_type 
      school
    end
  end
    
  def msg(type = :notice)
    case type
    when :initial
      "<h2>Good News</h2>Setup is complete. From now on, this is the first screen you will see when you log in. #{@school.domain_name}.littleredbrick.com is now ready for use! #{welcome}" 
    when :teacher_initial
      " If you want to skip the video, you can click #{where_teacher_clicks}"
    when :setup
      "<h2>Take 10 Minutes to Get Set Up</h2><p>Click <a href=\"/help/video/setup\">here</a> to see a short video describing the setup process, or follow the instructions below to get your new school going.</p>"
    when :welcome
      welcome
    end
  end

  def no_posts_msg
    if current_user.is_a?(Parent)
      "As a parent, you may join in online discussions with other parents and with school staff, and read discussions in your child&#8217;s classes. No posts have been written in those discussion groups recently."
    else
      "There have been no recent discussion posts. Feel free to #{link_to 'say something', personal_path} yourself".html_safe
    end
  end

  def secondary_nav
    super if controller.action_name == 'admin'
  end

  def truncated_post_link(post, topic)
    link_to truncate(post.body_html.gsub(/<[a-zA-Z\/][^>]*>/,''), 
                     :length => 40, :separator => ' ').html_safe, 
            forum_topic_path(discussable_for(topic), topic.forum, topic, 
            :anchor => topic.forum.posts.last.dom_id, 
            :page => topic.forum.posts.last.topic.last_page) 
  end

  def title
    action_name == "home" ? "Welcome" : "Admin"
  end

  def welcome
    "<h2>Want to know what you can do here?</h2>Here&#39;s a <a href='/help/video/tour'>link</a> to a tour of the site. You can always reach the tour and other helpful items by using the help link on this page."
  end

  def where_teacher_clicks
    if @sections.empty?
      "<a href=\"sections\">here</a> to start setting up your classes."
    elsif @sections.any?{|s| s.enrollment == 0}
      "the name of any section in the table below to enroll students in it."
    else
      "the name of any section under the \"Gradebook\" heading to start adding assignments."
    end
  end
end
