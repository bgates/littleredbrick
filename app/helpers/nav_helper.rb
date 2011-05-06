module NavHelper

  def active?(link)
    controller_name = controller.controller_name
    'active' if case link
      when 'admin'
        %w{administrators departments subjects school term track marking_period reported_grade}.include?(controller_name) || (controller_name == 'front_page' && action_name == 'admin') 
      when 'calendar'
        controller_name == 'events'
      when 'class'
        %w(assignments enrollments gradebook grades marks rollbook sections student teachers seating_chart attendance).include?(controller_name)
      when 'student'
        %w(children parents students).include?(controller_name) 
      when 'teacher'
        %w(sections teachers teacher_schedules gradebook assignments rollbook marks seating_chart).include?(controller_name) 
      when 'beast'
        %w{forums moderators monitorships posts topics users}.include?(controller_name)
      when 'help'
        %w(general faq page).include?(controller_name)
    end
  end

  def breadcrumbs(*args)
    li args.flatten.reject{|e| e.blank? }.join(arrow).html_safe, class: "breadcrumbs"
  end

  def help_link
    if controller.controller_name == 'front_page' && action_name == 'home'
      link_to 'Help', '/help', :title => 'Click for general help on the site'
    else
      link_to_unless(%w(general page faq).include?(controller.controller_name), 'Help', "/help/page/#{controller.controller_name}/#{action_name}", :title => 'Click for help on this page') do span 'Help' end
    end
  end

  def limit_visible_characters(nav = '')
    if nav.gsub(/<li>(?:<a.*?>)?([^<>]+)(?:<\/a>)?<\/li>/, '\1').length > 60
      first_line, nav_clone = '', nav.clone
      until first_line.length >= 60
        nav_clone.sub!(/<li>(?:<a.*?>)?([^<>]+)(?:<\/a>)?<\/li>/, '\1')
        first_line << $1
      end
      second_line = nav_clone[first_line.length..-1]
      replacement = second_line.sub(/<li/,"<li style=\"clear: left;\"")
      nav[-second_line.length..-1] = replacement
      @two_lines = true
    end
    nav.html_safe
  end
 
  def secondary_nav
    li(admins_link) +
    li(link_to_unless_current 'Departments', departments_path, 
       :title => 'Click to view and edit information about academic departments and subjects') +
    li(link_to_unless_current 'School', school_path, 
       :title => 'Click to view and edit enrollment and other information')+
    li(link_to_unless_current 'Term', 
       term_path(@last_term || @school.terms.first), 
       :title => 'Click to view and edit information about the academic term')
  end

  def tab_for_calendar
    li(link_to_unless_current("Calendar", calendar_path, :title => 'Click to see your school calendar'){span "Calendar"}, :id => active?('calendar'))
  end

  def tab_for_discussions
    li(link_to_unless_current("Discussions", personal_path, 
                      :title => 'Click to participate in online discussion groups with other people at your school'){span "Discussions"}, :id => active?('beast'))
  end

  def tab_for_students
    li(link_to_unless_current("Students", students_path, 
          :title => 'Click to see all student schedules'){span "Students"},
                                                 :id => active?('student'))
  end

end
