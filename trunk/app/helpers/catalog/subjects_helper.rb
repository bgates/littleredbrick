module Catalog::SubjectsHelper

  def active?(link)
    "active" if %w(class admin).include?(link)
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p("#{@subject.name} has been added to the #{@department.name} " +
        "department. To create sections of the subject, go to the " +
        "#{link_to 'teachers page', teachers_path}, select a teacher, and" +
        " click the 'edit teaching load' link.")
    when 'destroy'
      p "#{@subject.name} has been removed."
    when 'update'
      p "#{@subject.name} has been updated."
    end
  end

  def nav_for_action
    case action_name
    when 'new', 'create'
      "New Subject"
    when 'edit', 'update'
      [subject_link(@subject, @department), "Edit"]
    when 'show'
      @subject.name
    end
  end

  def nav_for_teacher_action
    action_name == 'index' ? 'Department' : 'Subject'
  end

  def secondary_nav
    current_user.admin?? secondary_nav_admin : secondary_nav_teacher
  end

  def secondary_nav_admin
    breadcrumbs admin_front_link,
                link_to('Departments', departments_path, 
                         :title => 'Click to view enrollment information organized by department'),
                link_to_unless(action_name == 'index', @department.name, 
                         department_subjects_path(@department), 
                         :title => "Click to see enrollment information for the #{@department.name} department"), 
                nav_for_action 
  end

  def secondary_nav_teacher
    breadcrumbs sections_front, section_page_link, nav_for_teacher_action
  end

  def section_title(section)
    h2(teacher_link(section.teacher, 
                    current_user.may_see?(section.teacher)) + 
    arrow +
    link_to_if(current_user.may_see?(section), (section.time.nil?? 'View section' : section.time), section_path(section), :title => "See class-level data for #{section.teacher.display_name}&#39;s #{section.time.nil?? '' : 'period ' + section.time} class".html_safe))
  end

  def title
    case action_name
    when 'new', 'create'
      "New #{@department.name} Subject"
    when 'edit', 'update'
      "Edit #{@subject.name}"
    when 'show'
      @subject.name
    when 'index'
      "#{@department.name} Department"
    end + title_suffix
  end

  def title_suffix
    current_user.admin?? ' | Admin' : ' | Sections'
  end
end

