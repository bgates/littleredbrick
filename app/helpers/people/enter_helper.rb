module People::EnterHelper
  include AccountUploadHelper

  def action_title
    if action_name == 'multiple'
      'Multiple'
    else
      [link_to('Multiple', enter_multiple_path), "Enter #{action_name.capitalize}"]
    end
  end

  def active?(link)
    'active' if link == params[:id].singularize
  end

  def collection
    case params[:id]
    when 'teachers'
      [link_to('Teachers', teachers_path), 
       link_to('New Teacher', new_teacher_path)]
    when 'students'
      [link_to('Students', students_path),
      link_to('New Student', new_student_path)]
    else
      [admin_front_link,
       link_to('Administrators', administrators_path),
       link_to('New', new_administrator_path)]
    end
  end

  def detail_header
    "#{user_title}#{name}#{grade}#{login}".html_safe
  end

  def grade
    th 'Grade' if @type == 'students'
  end

  def login
   th 'Login/Password' if @new_people.any?{|u| u.authorization && !u.authorization.errors.empty?}
  end

  def name
    %w(First Last ID).map{|name| th name }.join
  end

  def secondary_nav
    breadcrumbs collection, action_title
  end

  def title
    "#{@page_h1} | #{title_suffix}"
  end

  def title_suffix
    case params[:id]
    when 'teachers', 'students'
      params[:id].capitalize
    else
      'Admin'
    end
  end

  def type_specific_info
    case @type
    when 'students'
      'grade (or year)'
    else
      'title (Mr/Mrs/Ms etc)'
    end
  end

  def user_title
    th 'Title' unless @type == 'students'
  end

end
