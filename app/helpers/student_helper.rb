module StudentHelper

  def author(post)
    td link_to(post.user.display_name, reader_path(@section, post.user)) 
  end
  
  def author_header
    th "Author"
  end
  
  def class_link(section)
    link_to_unless_current section.name, student_class_path(section), 
      :title => "Click to see more about #{section.name}"
  end

  def due_date_for(assignment)
    (assignment.date_due || Date.parse(assignment.individual_date)).strftime("%a %b %d")
  end
  
  def empty_posts
    "There have been no recent comments in the #{link_to 'forums for this class', forums_path(@section)}".html_safe
  end

  def his_or_your
    @student == current_user ? 'your' : @student.first_name + '&#8217;s'
  end
  
  def grade(assignment)
    if assignment.score.to_i.to_s == assignment.score.to_s && assignment.point_value > 0
      100 * assignment.score.to_f / assignment.point_value
    else
      '-'
    end
  end
  
  def link_to_more_posts
    link_to "#{@section.name} forums", forums_path(@section)
  end
  
  def secondary_nav
    case controller.action_name
    when 'index', 'show'
      @sections.sort_by(&:time).map{|section| li class_link(section)}.join.html_safe
    when 'assignments'
      breadcrumbs class_link(@section), 'Assignments'
    when 'assignment'
      breadcrumbs(class_link(@section), 
                 link_to('Assignments', student_assignments_path(@section),
                 :title => "Click to see information about all #{@section.name} assignments"), 
                 @assignment.title)
    end
  end
  
  def section_title(section)
    h3 link_to(section.name_and_time, student_class_path(section)), :title => "Click to see more information about #{his_or_your} #{section.name} class"
  end
end
