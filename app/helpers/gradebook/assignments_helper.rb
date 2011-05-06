module Gradebook::AssignmentsHelper

  def assignments_link
    condition = action_name == 'index' || !current_user.may_see?(@section)
    link_to_unless(condition, 'Assignments', 
                   section_assignments_path(@section), 
    :title => "Click to see information on all assignments for this #{@section.name} class, including class averages for each assignment") {normal_text('Assignments')}
  end

  def due_date_for_each?
    case action_name
    when 'edit'
      (@assignment.date_due.nil? && params[:due] != 'all') || 
       params[:due] == 'individual'
    when 'new'
      params[:due] == 'individual'
    when 'update', 'create'
      @grades
    end
  end

  def marking_period_indices
    @marking_periods.collect do |mp| 
      [ @marking_periods.index(mp)+1, mp.reported_grade_id ] 
    end
  end

  def msg(type = :notice)
    msg_head(type) +
    case action_name
    when 'create'
      p("The #{@assignment.category} has been added as assignment " +
        "##{@assignment.position} and a default grade, '-', was given to " +
        "every student in the class. This score does not count for or " +
        "against a student. To grade the assignment, replace the '-' with" +
        " numerical scores. To edit the assignment, click  " +
        "##{@assignment.position} in the header.")
    when 'destroy'
      p "Assignment #{@assignment.position} was deleted."
    when 'update'
      p "The assignment was updated."
    end
  end

  def nav_for_action
    case action_name
    when 'new', 'create'
      "New Assignment"
    when 'edit', 'update'
      [link_to(@assignment.title, 
              section_assignment_path(@section, @assignment), 
              :title => 'Click to see detailed information on this assignment, including each student&#39;s score'.html_safe), 'Edit']
    when 'show'
      @assignment.title
    when 'performance'
      'Performance'
    end
  end

  def new_or_edit_link(param)
    @assignment.new_record?? new_section_assignment_path(@section, param) : edit_section_assignment_path(@section, @assignment, param)
  end

  def title
    title_start + title_end
  end

  def title_start
    case action_name
    when 'index'
      "#{teachers}#{@section.time_and_name} Assignments"
    when 'show'
      "#{teachers}#{@section.time_and_name} Assignment #{@assignment.position}"
    when 'edit', 'update'
      "Edit #{@section.time_and_name} Assignment #{@assignment.position}"
    when 'new', 'create'
      "New #{@section.time_and_name} Assignment"
    when 'performance'
      "#{teachers}#{@section.time_and_name} Class Performance on Assignments"
    end
  end

  def title_end
    if current_user.admin?
      " | Teachers"
    else
      " | Sections"
    end
  end

  def secondary_nav
    breadcrumbs teacher_section_gradebook_links, assignments_link, nav_for_action
  end

  def qualifier
    !params[:category].nil?? 'category' : !params[:marking_period].nil?? 'marking period' : 'section'
  end
end

