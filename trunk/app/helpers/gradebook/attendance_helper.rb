module Gradebook::AttendanceHelper

  def absence_for(student, date)
    if absence = student.absences.detect{|abs| abs.date == date}
      content_tag :span, absence_code(absence), :title => absence_name(absence)
    end
  end

  def absence_or_form_element_for(student, date)
    if date == @date       
      select_tag "section[absences][#{student.id}]", options_for_select(options, absence_selection_for(student, date)) 
    else
      absence_for(student, date)
    end
  end

  def absence_selection_for(student, date)
    if absence = student.absences.detect{|abs| abs.date == date}
      absence.code
    end
  end

  def conditional_date
    @date unless @date == Date.today
  end

  def nav_for_action
    case action_name
    when 'edit', 'update'
      [link_to('Attendance', section_attendance_path(@section, Date.today),
        :title => 'Click to see attendance information for the section'),
        'Edit']
    when 'show'
      "Attendance"
    end
  end

  def options
    @school.absence_codes(false).map{ |code, text| [text, code] }.unshift(['Present', nil])
  end

  def secondary_nav
    breadcrumbs teacher_section_gradebook_links, nav_for_action
  end

  def title
    "#{teachers}#{title_prefix} #{@section.time_and_name} Attendance | #{title_suffix}"
  end

  def title_prefix
    'Edit' unless action_name == 'show'
  end

  def title_suffix
    current_user.admin?? 'Teachers' : 'Sections'
  end
end

