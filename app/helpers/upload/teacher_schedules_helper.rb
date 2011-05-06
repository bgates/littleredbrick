module Upload::TeacherSchedulesHelper

  def active?(link)
    "active" if %w(class teacher).include?(link)
  end

  def current_action
    if params[:upload].blank? && params[:extension].blank?
      'Upload Teacher Schedules'
    else
      [link_to('Upload Teacher Schedules', new_teaching_load_upload_path), 'Confirm Format']
    end
  end

  def secondary_nav
    breadcrumbs(link_to('Teachers', teachers_path), current_action)
  end

  def term_selector
    if @school.terms.count > 1
      label_tag('current', "Are these classes in the current term?") + 
      check_box_tag('current', true) 
    else
      "&nbsp;#{hidden_field_tag 'current', true}"
    end
  end

  def title
    "#{@page_h1} | Teachers"
  end
end

