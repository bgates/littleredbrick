module Help::GeneralHelper      

  def nav_for_action
    @path.split('/').reject{|elm| elm == 'index' }.map{|elm| elm.titleize }.join(' ')
  end

  def secondary_nav
    return unless current_user.is_a?(Staffer) #&& action_name != 'index'
    breadcrumbs link_to('Help', general_help_path), video_menu, nav_for_action 
  end

  def setup_task_list
    if session[:initial] 
      h2("Setup Task List") + ol(
      li(link_to_unless_current('Set up the term', 
         :action_name => 'term') + term_page_two 
       ) +
      li(link_to_unless_current 'Add user accounts', 
         :action_name => 'users') +
      li(link_to_unless_current 'Set up the course catalog',
         :action_name => 'catalog') +
      li(link_to_unless_current 'Set teaching assignments',
         :action_name => 'teaching_load') +
      li(link_to_unless_current "Enroll students in classes",
         :action_name => 'enrollment') 
      ) + link_to('Return to the front page', '/')
    end
  end

  def term_page_two
    current_page?('/help/setup/term_2') ? '<br/>Term Setup Example'.html_safe : ''
  end

  def title
    "#{@page_h1} | Help"
  end

  def them_or_you
    (current_user.is_a?(Student) || current_user.is_a?(Parent)) ? 'you' : 'them'
  end
  
  def video                              
    if current_user.is_a?(Student) || current_user.is_a?(Parent)
      "/video/file/#{@video || params[:id]}"
    elsif current_user.is_a?(Teacher) && session[:admin]
      "/video/staffer/#{@video || params[:id]}"
    else
      "/video/#{current_user.class.to_s.downcase}/#{@video || params[:id]}"
    end
  end

  def video_header(rowspan, header_text, text, id, duration)
    tr(th(header_text, :rowspan => rowspan) +
       td(link_to(text, video_help_path(id)), :class => 'text') +
       td(duration), :class => cycle('odd', 'even'))
  end

  def video_menu
    link_to "Video Menu", general_help_path('video_menu') if @video
  end

  def video_row(text, id, duration)
   tr(td(link_to(text, video_help_path(id)), :class => 'text') +
      td(duration), :class => cycle('odd', 'even'))
  end

end
