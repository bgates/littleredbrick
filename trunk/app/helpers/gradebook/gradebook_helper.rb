module Gradebook::GradebookHelper

  def assignment_titles
    @all_assignments.reverse.map do |a| 
      ["#{a.position}: #{truncate(a.title, :length => 10)}", a.position]
    end
  end

  def calculate(arr)
    arr[1] == 0? 'N/A' : number_with_precision(100*(arr[0].to_f/arr[1]), :precision => 1)
  end

  def add_assignment_marker
    link_to_if(add_marker?, image_tag('add_16_ie.png', 
                                      {:alt => "Add Assignment", 
                                       :title => "Add Assignment", 
                                       :align => 'left'}), 
                            new_section_assignment_url(@section), 
                            :class => 'add'){add_assignment_direction_marker}
  end

  def add_assignment_direction_marker
    image_tag('add_16.png', {:alt => "To add new assignments, go to most recent assignment view", :title => "To add new assignments, go to current assignment view", :align => 'left'})
  end

  def add_marker?
    @assignments.empty? || 
    @assignments.last.position == @all_assignments.length
  end

  def assignment_list_if_it_exists
    if @assignments.empty?
      th '&#160;'.html_safe, :class => 'remove_after_assign_added'
    else
      render :partial => 'assignment', :collection => @assignments, 
             :locals => {:section => @section}
   end
  end

  def assignment_range
    case @assignments.length
    when 0
      th '&nbsp;'.html_safe
    when 1
      th '1', :title => 'Grade for assignment 1'
    else
      finish = @assignments.length + @start - 1
      th "#{@start}-#{finish}", :title => "Average for assignments #{@start}-#{finish}".html_safe
    end
  end

  def initial_instructions
    if @assignments.empty?
      tr(td('Click the plus sign above to add assignments', :colspan => 5),
         :class => 'setup')
    elsif @students.empty?
      tr(td('Click the plus sign below to add students', 
          :colspan => [5, @assignments.length + 4].max), :class => 'setup')
    end
  end

  def initial_msg                                          
    if @all_assignments.length < 6
      "The changes you made automatically updated the marking period " +
      "grade for each student (last column). Click the 'set marking " +
      "period' link in the right sidebar if you want to adjust any " +
      "marking period grades (to weight assignments by category, for " +
      "instance, or to give a student a few points 'off the books'.)" 
    end
  end

  def msg(type = :notice)
    msg_head(type) + 
    case type
    when :error
      p "It is not possible to update grades until at least one assignment has been created and one student enrolled in this class."
    when :notice
      p "Gradebook was successfully updated. #{initial_msg}"
    when :now
      p "There was a problem updating the grades. Graded assignments must be given numerical scores. Enter '-' (without the quotes) to mark an assignment as ungraded. Please correct the errors (marked in red) and resubmit."
    when :sort
      p "The gradebook order was updated successfully."
    end
  end

  def msg_head(type)
    [:notice, :sort].include?(type) ? h2('Good News') : h2('Bad News')
  end

  def secondary_nav
    if action_name == 'sort'
      [teacher_section_gradebook_links, 'Sort Students']
    else
      limit_visible_characters(section_nav)
    end
  end

  def section_nav
    @sections.map do |section| 
      li(link_to_unless_current(section.name_and_time(false), 
                                section_gradebook_path(section), 
       :title => "Click to see the gradebook for #{section.name_and_time}"))
    end.join
  end

  def sidebar_calendar
    calendar({:year => @year, :month => @month, :table_class => 'sideCalendar', :other_month_class => 'outOfMonth'}) do |d|
      cell_text = ""
      cell_attrs = {:class => 'day'}
      if a = @all_assignments.detect{|a|a.date_due == d}
        cell_text << link_to(d.mday, section_gradebook_path(@section, :start => a.position), :title => "Find assignment #{a.position.to_s} in the gradebook")
        cell_attrs[:class] = 'specialDay'
      else
        cell_text << "#{d.mday}"
      end
      [cell_text, cell_attrs]
    end
  end

end

