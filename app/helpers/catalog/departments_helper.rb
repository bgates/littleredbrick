module Catalog::DepartmentsHelper

  def active?(link)
    "active" if link == 'admin'
  end

  def link_for_new_subjects
    if @department.subjects.length > @prev_count
      " To give a teacher a section of one of the new subjects, go to the" +
      " #{link_to 'teacher index', teachers_path}, click the " +
      "teacher&#39;s name, and then click the 'edit teaching load' link." 
    end
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p("Successfully created the #{@department.name} department and " + 
        "#{@department.subjects.length} subjects. To give a teacher a" +
        " section of one of the new subjects, go to the " + 
        "#{link_to 'teacher index', teachers_path}, click the " + 
        "teacher&#39;s name, and then click the 'edit teaching load' link.")
    when 'destroy'
      if type == :notice
        p "The #{@department.name} department has been removed."
      else
        p "The #{@department.name} department could not be deleted."
      end
    when 'update'
        p("The department and its subjects were updated. " +
          "#{link_for_new_subjects}")
    end
  end

  def nav_for_action
    case action_name
    when 'new', 'create'
      "New Department"
    when 'edit', 'update'
      [link_to(@department.name, department_subjects_path(@department),
               :title => "Click to view enrollment information for subjects in the #{@department.name} department"), "Edit"]
    end
  end
  
  def nav_for_index
    link_to('Departments', departments_path, :title => 'Click to view and 
                  edit information about academic departments and subjects')
  end

  def new_subject_link
    if @department.id
      link_to 'New Subject', new_department_subject_path(@department), 
        :id => 'new_subject', :class => @department.id, 
        :title => 'Click to add a new subject to the department'
    else
      link_to 'New Subject', {:subjects => (params[:extra_sub] || 0) + 1}, 
        :id => 'new_subject', :title => 'Click to add a new subject to 
                                         the department'
    end
  end

  def title
    "#{@page_h1} | Admin"
  end

  def secondary_nav
    if controller.action_name == 'index'
      super
    else
      breadcrumbs admin_front_link, nav_for_index, nav_for_action
    end
  end

end
