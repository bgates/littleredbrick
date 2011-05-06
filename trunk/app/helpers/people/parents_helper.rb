module People::ParentsHelper

  def last_login(parent = @parent)
    if parent.never_logged_in?
      "#{parent.display_name} has never logged in."
    else
      "Last login #{parent.last_login.strftime('')}"
    end
  end

  def nav_start
    if @student
      link_to @student.full_name, student_url(@student), :title => "Click to see an overview of #{@student.first_name} &#39;s academic performance"
    end
  end

  def parent_link 
    if @student
      link_to 'Parents', student_parents_url(@student), :title => "Click to see a list of #{@student.first_name}&#39;s parents"
    else
      link_to 'Parents', parents_url
    end
  end
  
  def secondary_nav
    breadcrumbs link_to('Students', students_path), nav_start, nav_finish
  end

  def nav_finish
    case action_name
    when 'index'
      'Parents'
    when 'show'
      [parent_link, @parent.full_name]
    when 'edit', 'update' #TODO what if there's no @student?
      [parent_link, 
      link_to(@parent.full_name, student_parent_url(@student, @parent), 
              :title => "Click to see information about #{@parent.full_name}"), 'Edit']
    when 'new', 'create'
      [parent_link, 'New Parent']
    end
  end

  def title
    case action_name
    when 'show'
      @parent.full_name
    when 'edit', 'update'
      "Edit Parent"
    when 'index'
      'Parents'
    when 'new', 'create'
      "New Parent"
    end + ' | Students'
  end

end
