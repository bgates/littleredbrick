module SectionsHelper

  def bounds_check(i)
    'fieldWithErrors' if @section.grade_scale[i][0].last <= @section.grade_scale[i - 1][0].last
  end

  def grades_check(i)
    'fieldWithErrors' unless @section.grade_scale_grades.one? do |g|
      g == @section.grade_scale_grades[i]
    end
  end

  def msg(type = :notice)
    case action_name
    when 'destroy'
      h2("Good News") + p("The section was deleted.") 
    when 'index'
      h2("You need to set up your classes") + 
      p("Select the departments first, then the subjects.") 
    when 'update'
      h2("Good News") + p("The section has been updated.") 
    end
  end

  def secondary_nav
    case action_name
    when 'index', 'show'
      if current_user.admin?
        breadcrumbs link_to('Teachers', teachers_path),
                    teacher_link(@teacher), @section.name_and_time
      else
        limit_visible_characters(section_nav)
      end
    when 'edit', 'update'
      breadcrumbs sections_front,
                  teachers_front,
                  teacher_link(@teacher, current_user.admin?){|link| nil},
                  section_link(@section, @section.name_and_time), 
                  'Edit'
    end
  end

  def section_nav
    @sections.map do |section| 
      li link_to_unless_current(section.name_and_time(false), 
                                section_path(section), :title => 
      "Click to see the class overview for #{section.name_and_time}")  
    end.join
end

  def section_title(section)
    h2(link_to_unless_current(section.name_and_time, section_path(section), 
                              :title => "Click to see the class overview for #{section.name_and_time}")) +
    h3(link_to_unless_current('Gradebook', section_gradebook_path(section)))  unless @section
  end

  def time
    ", Period #{@section.time} " unless @section.time.nil?
  end

  def title
    "#{title_prefix}#{title_suffix}"
  end

  def title_prefix
    case action_name
    when 'index'
      'Sections'
    when 'edit', 'update'
      "Edit #{teachers}#{@section.name_and_time}"
    when 'show'
      "#{teachers}#{@section.name_and_time}" 
    end 
  end

  def title_suffix
    if current_user.admin?
      " | Teachers" 
    else
      ' | Sections' unless action_name == 'index'
    end
  end

  def unenrollment_link
    if params[:unenroll].blank?
      link_to_if @section.enrollment > 0, 'Remove student', 
        {:unenroll => 'unenroll'}, 
        {:id => 'unenrollment', :title => 'Click to choose students to remove from the class'}
    else
      link_to 'Stop', 
        {:unenroll => nil},
        {:id => 'unenrollment', :title => 'Click when you are finished removing students from the class'}
    end
  end

end
