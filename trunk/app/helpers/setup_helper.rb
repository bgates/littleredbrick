module SetupHelper

  def checkmark(alt = 'Complete')
    image_tag '/images/small_check.jpeg',
              :alt => "(#{alt})", :title => alt
  end
  
  def completion_notice
    content_tag(:div, 
      content_tag(:h2, "Setup Is Complete!") +
      content_tag(:p, "At least it looks that way to us, since every class has students enrolled in it. If you want to continue enroll students for teachers, #{link_to('click here', teachers_path)} and choose a class. Otherwise, you can #{link_to('exit setup', :setup => true)}.".html_safe), :id => 'notice')
  end

  def conditional_term_link
    if @terms.length > 0
      "A term has already been created; to review its details, click #{link_to 'here', term_path(@terms[0])}.".html_safe
    else
      link_to "Set up a new term", new_term_path
    end
  end

  def conditional_catalog_link
    if @subjects > 0
      "The catalog has already been set up with #{pluralize(@school.departments.length, 'department')} and a total of #{pluralize(@subjects, 'subject')} in the system. To review its details, click #{link_to 'here', edit_catalog_path}.".html_safe
    else
      link_to "Create catalog", new_catalog_path
    end
  end

  def conditional_setup_links
    if @teachers.length > 0 && @subjects > 0
      teacher_setup_links
    else
      "You cannot assign classes to teachers until you have #{created_teacher_accounts}#{created_subjects}".html_safe
    end
  end

  def conditional_class_assignment_link 
    if @all_enrolled
      completion_notice
    elsif @teachers_with_classes > 0 && @students > 0
      p "If you want to enroll students for teachers, #{link_to 'click here', teachers_path} and choose a class. If you want to have teachers enroll their own students, #{link_to 'click here', :setup => true} to exit setup.".html_safe
    else
      ''
    end
  end

  def conditional_create_students_link
    link_to_unless @terms.empty?, 'students', enter_multiple_path('students')
  end

  def conditional_create_teachers_link
    link_to_unless((@terms.empty? || !@school.may_add_more_teachers?), 'teachers', enter_multiple_path('teachers'))
  end
    
  def conditional_completion_link
    "If you #{who_should_enter_class_data}, #{link_to 'click here', home_path(:setup => true)} to exit the setup process."
  end

  def conditional_teachers_link
    link_to_unless((@terms.empty? || @teachers.empty?), pluralize(@teachers.length,'teacher'), teachers_path, :title => 'Click to see the names of the teachers who have accounts')
  end

  def created_teacher_accounts
    if @teachers.length == 0
      "created #{link_to_unless(@terms.empty?, 'teacher accounts', 
      enter_multiple_path('teachers'))}" 
    end
  end

  def created_subjects
    if @subjects == 0
      "#{' and' if @teachers.length == 0} 
      a #{link_to 'subject catalog', new_catalog_path}"
   end
  end

  def pending_accounts
    "You just added #{flash[:import][:number]} accounts for #{flash[:import][:type]}. Those may not be reflected in the account totals yet. We&#39;re working on it.".html_safe if flash[:import]
  end
  
  def teacher_setup_links
    if @teachers_with_classes == @teachers.length
      "Every teacher with an account has been assigned at least one class. #{conditional_completion_link}"
    else
      "#{link_to('Click here', teachers_path)} to assign classes to teachers. Currently #{pluralize(@teachers_with_classes, 'teacher')} #{@teachers_with_classes == 1 ? 'has' : 'have'} classes assigned to them. #{conditional_completion_link}".html_safe
    end
  end

  def term_reminder
    "Before you create accounts for other people, you have to set up the academic term." if @terms.empty?
  end

  def who_should_enter_class_data
    if @teachers.length > @teachers_with_classes
      'want teachers to be responsible for entering their own classes'
    else
      'have finished assigning classes to teachers and want them to be responsible for enrolling students in their classes'
    end
  end
end
