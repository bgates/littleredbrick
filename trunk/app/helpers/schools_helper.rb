module SchoolsHelper

  def day_length
    @last_term.low_period == 1 ? @last_term.high_period : 
                                 @last_term.high_period + 1 
  end

  def enrollment
    begin
      number_with_precision(@enrollment.to_f / @sections.size, :precision => 1) 
    rescue 
      '&nbsp;' 
    end
  end

  def grade_cycle
    @school.high_grade - @school.low_grade % 2 == 0 ? 'odd' : 'even' 
  end

  def msg(type = :notice)
    h2(msg_head) + 
    case action_name
    when 'create'
      p "You have created a new account with login '#{@user.authorization.login}' and password '#{@user.authorization.password}'. Login here to get started setting up the new school. To reach this page in the future, go to <br/><span class=\"huge\">http://#{@school.domain_name}.littleredbrick.com/login</span>"
    when 'update'
      p "The school information has been updated."
    when 'search'
      p "To reach this page in the future, go to <span style='font-size:2em'>http://#{@school.domain_name}.littleredbrick.com/login</span>"
    end
  end

  def msg_head
    action_name == 'search' ? 'Here is your login page' : 'Good News'
  end

  def secondary_nav
    case action_name
    when 'show'
      super
    when 'edit', 'update'
      breadcrumbs(admin_front_link, link_to('School', school_path, :title => 'Click to view and edit enrollment and other information'), 'Edit')
    end
  end

  def title
    case action_name
    when 'edit', 'update'
      'Edit School | Admin'
    when 'show'
      "#{@school.name} | Admin"
    end 
  end

  def tracks
    unless @last_term.tracks.length == 1 
      "<dt>Tracks</dt><dd>#{@last_term.tracks.length}</dd>".html_safe
    end
  end
end

