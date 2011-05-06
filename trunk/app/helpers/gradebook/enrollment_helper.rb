module Gradebook::EnrollmentHelper
#TODO move sort to gradebook; remove references here
  def author(post);end

  def author_header;end

  def day_link(day)
    link_to day.mday, section_attendance_path(@section, :date => day),
    :title => "Click to see class attendance information for the week of #{day.strftime("%B %d")}"
  end

  def link_to_more_posts
    link_to "More comments by #{@student.first_name}", reader_path(@section, @student)
  end

  def month_calendar(year, month)
    calendar({:year => year, :month => month, :table_class => 'sideCalendar', :other_month_class => 'outOfMonth'}) do |d|
      cell_text = ""
      cell_attrs = {:class => 'day'}
      cell_text << day_link(d)
      if a = @absences.detect{|a|a.date == d}
        cell_text << content_tag(:span, absence_code(a),
          :class => 'absence', :title => absence_name(a))
        cell_attrs[:class] = 'specialDay'
      end
      [cell_text, cell_attrs]
    end
  end

  def msg(type = :notice)
    case action_name
    when 'create'
      case type
      when :oops
        h2("Oops") + p("Please enter at least one name.")
      when :notice
        "#{@student.full_name} has been added to this section"
      when :now
        "Identify a unique student to add them to this section"
      end
    when 'destroy'
      "<h2>Good News</h2>#{@student.full_name} has been unenrolled from the #{@section.name} class."
    end
  end

  def nav_for_action
    'Enroll Students'
  end

  def secondary_nav
    breadcrumbs teacher_page_link, sections_front,
                section_page_link, nav_for_action
  end

  def section_identifier
    "#{section_owner} #{section_time} #{@section.name} class.".html_safe
  end

  def section_owner
    @section.teacher_id == current_user.id ? 'your': "#{@section.teacher.display_name}&#39;s"
  end

  def time(section)
    section.time.nil?? 'View section' : section.time
  end

  def title
    "Enroll Students in #{teachers} #{@section.name_and_time} |#{title_end}"
  end

  def title_end
    current_user.admin?? ' Teachers' : ' Sections'
  end

end

