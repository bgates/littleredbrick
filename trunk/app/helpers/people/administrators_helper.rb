module People::AdministratorsHelper

  def add_teacher
    if @school.may_add_more_teachers?
      "If you are sure the teacher should be present, click 
      #{link_to 'here', new_teacher_path} to create the teacher account."
    end
  end
  
  def new_link_if_allowed
    if @teachers.empty?
      li "No teacher with that name was found.#{add_teacher}".html_safe
    end
  end
  
  def secondary_nav
    case controller.action_name
    when 'index'
      super
    when 'show'
      breadcrumbs admin_front_link, admins_link, @admin.display_name
    when 'edit', 'update'
      breadcrumbs admin_front_link, admins_link, 
                  link_to(@admin.display_name, administrator_path(@admin), 
                          :title => "Click to see more information on 
                            #{@admin.display_name}&#39;s account"), 'Edit' 
    when 'new', 'create'
      breadcrumbs admin_front_link, admins_link, 'New Administrator'
    end
  end

  def title
    case action_name
    when 'index'
      'Administrators'
    when 'show'
      "#{@admin.display_name}"
    when 'edit', 'update'
      "Edit #{@admin.display_name}"
    when 'new', 'create'
      'New Administrator'
    when 'search'
      'Make Teacher Admin'
    end + ' | Admin'
  end
end
