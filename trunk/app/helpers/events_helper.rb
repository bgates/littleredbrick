module EventsHelper

  def calendar_link(month, year = @year)
    link_to Date::MONTHNAMES[month], calendar_path(year, month), 
           :title => "Click to see calendar for #{Date::MONTHNAMES[month]}"
  end

  def class_for(event)
    if event.is_a?(Assignment) || event.is_a?(Grade)
      "class#{position(event.section_id)} assignment_#{event.section_id}"
    else
      case event.invitable_type
      when 'User', 'Family'
        "personal event_#{event.invitable_type.downcase}"
      when 'School'
        "schoolwide event_school"
      when 'Section'
        "class#{position(event.invitable_id)} event_#{event.invitable_id}"
      when 'Teachers', 'Staff'
        "event_#{event.invitable_type.downcase}"
      end
    end
  end

  def day_link(date, options = {})
    link_to date.day, day_path(date.year, date.month, date.day),
     {:title => "Click to see every event on #{Date::MONTHNAMES[date.month]} #{date.day}"}.merge(options) 
  end

  def edit_path_check_for_grade(e)
    case e.class.to_s
    when 'Grade'
      edit_section_assignment_path(e.section_id, e.assignment_id)
    when 'Assignment'
      edit_section_assignment_path(e.section_id, e)
    else edit_event_path(e)
    end
  end

  def event_assignment_link(event, trunc, options = {})
    link_to truncated(event.title, trunc), 
      assignment_as_event_path(event, options), 
      :title => "#{event.section.name} : #{event.title}", 
      :class => class_for(event)
  end

  def event_calendar
    calendar({:year => @year, :month => @month, :table_class => 'cal', 
              :other_month_class => 'outOfMonth'}) do |d|
      cell_text = day_link(d, :class => 'date')
      cell_attrs = {:class => 'day', :id => "#{d}"}
      cell_attrs = {:class => 'event'} if d == Date.today
      if @events.any?{|event| event.date == d}
        cell_attrs[:class] = 'specialDay'
        cell_text << events_on(d)
        [cell_text.html_safe, cell_attrs]
      end
    end
  end

  def event_grade_link(event, trunc)
    if current_user.is_a?(Parent) || current_user.is_a?(Student)
      event_assignment_link(event.assignment, trunc, :grade => event)
    else
      link_to truncated_student(event, trunc), 
        assignment_as_event_path(event.assignment, :grade => event), 
        :title => "#{event.section.name} : #{event.assignment.title}
        (#{event.rollbook_entry.student.full_name})", 
        :class => class_for(event.assignment)
    end
  end

  def event_link(event, trunc)
    if event.id
      link_to truncated(event.name, trunc), event_path(event), 
        :title => event.name, :class => class_for(event)
    else
      event_span(event, trunc)
    end
  end

  def event_span(event, trunc)
    span truncated_span(event.name, trunc), :class => 'nonacademic'
  end

  def events_on(day)
    ul(@events.select{|event| event.date == day }.map do |event| 
      li link_for(event) 
    end.join.html_safe)
  end
   
  def id_only(assignments, academic, non_academic_events)
    if !assignments.empty?
      assignments.first.section.name_and_time(false)
    elsif !academic.empty?
      @sections.detect{|s| s.id == academic.first.section_id}.name_and_time(false)
    elsif !non_academic_events.empty?
      non_academic_events.first.audience.sub(/User/, 'Personal')
    end
  end

  def link_for(event, trunc = true)
    case event
    when Assignment
      event_assignment_link(event, trunc)
    when Grade
      event_grade_link(event, trunc)
    else
      event_link(event, trunc)
    end
  end

  def next_month_link
    if @month < 12
      calendar_link(@month + 1)
    else
      calendar_link(1, @year + 1)
    end
  end

  def position(index)
    @sections.index(@sections.detect{|s| s.id == index}) + 1
  end

  def previous_month_link
    if @month > 1
      calendar_link(@month - 1)
    else
      calendar_link(12, @year - 1)
    end
  end

  def return_link
    link_to 'Return to calendar', return_path
  end

  def return_path
    if @event.date.blank? 
      calendar_path(Date.today.year, Date.today.month)
    else
      calendar_path(@event.year, @event.month)
    end
  end                                       

  def secondary_nav
    if action_name == 'index' && params[:day].blank?
      li(previous_month_link) +
      li(Date::MONTHNAMES[@month]) +
      li(next_month_link)
    elsif action_name == 'new' || action_name == 'create'
      breadcrumbs calendar_link(@event.date.month), 'New Event'
    elsif action_name == 'edit' || action_name == 'update'
      breadcrumbs(calendar_link(@event.date.month), day_link(@event.date), 
                  link_to(@event.name, event_path(@event), 
                  :title => 'Click to see this event'), 'Edit')
    elsif !params[:day].blank?
      breadcrumbs(calendar_link(@month), params[:day])
    else
      breadcrumbs(calendar_link(@event.date.month, @event.date.year), 
                  day_link(@event.date), @event.name)
    end
  end

  def truncated_span(name, trunc)
    if trunc
      "#{truncate(name, :length => 35, :separator => ' ')}<br />".html_safe
    else
      name
    end
  end

  def title
    case action_name
    when 'index'
     'Events'
    when 'new', 'create'
     'New Event'
    when 'edit', 'update'
     'Edit Event'
    when 'assignment'
      "#{@section.name} Assignment: #{@assignment.title}"
    when 'show'
     @event.name
    end
  end

  def truncated(name, trunc)
    trunc ? truncate(name, :separator => ' ') : name
  end

  def truncated_student(event, trunc)
    if trunc
      truncate(event.rollbook_entry.student.full_name, :separator => ' ') 
    else
      "#{event.assignment.title}(#{event.rollbook_entry.student.full_name})"
    end
  end

  def unique_audience?
    (@ev.select{|e| !e.id.nil?}.map{|e|e.unique_id} + 
     @assignments_and_grades.map(&:section_id)).uniq.length < 2
  end
end

