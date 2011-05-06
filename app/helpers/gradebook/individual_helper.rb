module Gradebook::IndividualHelper

  def action_title
    "&#39;s #{action_name.capitalize}" unless action_name == 'show'
  end

  def empty_posts
    "#{@student.first_name} has contributed no comments to the #{link_to 'forums for this class', forums_path(@section), :title => 'Click to see all the forums for this class'}".html_safe
  end

  def nav_for_action
    case action_name
    when 'show'
      @section.name
    else
      [rbe_link(@student, @section, @section.name), action_name.capitalize]
    end
  end

  def secondary_nav
    breadcrumbs link_to('Students', students_path), 
                link_to(@student.full_name, student_path(@student)),
                nav_for_action 
  end

  def section_and_gradebook_link
    content_tag :h2,
      "#{section_link(@section, @section.name,
                   current_user.may_see?(@section))}
       #{section_time}(#{teacher_or_gradebook})".html_safe,
                   :style => 'display:inline;margin-right:2em'
  end

  def title
    "#{@student.full_name}#{action_title} in #{@section.name} | Students"
  end

end

