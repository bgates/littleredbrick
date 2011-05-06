module TeachingLoadHelper

  def active?(link)
    "active" if %w(class teacher).include?(link)
  end

  def colspan
    1 + (@low_period.nil?? 0 : 1) + (@tracks.length == 1 ? 0 : 1) 
  end

  def conditional_track_selector(s)
    if @tracks.length > 1
      td s.select("track_id", 
      options_from_collection_for_select(@tracks, "id", "position", s.object.track_id)) 
    elsif @tracks.length == 1    
      td(s.hidden_field("track_id"), :style => "display:none")
    end
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p "#{whose_class_list} has been saved. To enroll students in one of these classes, #{msg_by_redirect_path}"
    when 'update'
      p "#{whose_class_list} has been saved. To enroll students in any of the new classes, click the class name."
    end
  end

  def msg_by_redirect_path
    if current_user.admin?
      "click its name in the list below."
    elsif params[:term].blank?
      "click its name or the link to its gradebook."
    else
      "enter their names in the form below."
    end
  end

  def secondary_nav
    if @teacher == current_user
      breadcrumbs sections_front, "#{params[:term] ? 'Next Term ' : ''}Teaching Load"
    else
      breadcrumbs teachers_front, 
                  link_to_unless(@sections.all?(&:new_record?), 
                  @teacher.display_name, teacher_path(@teacher)) { 
                    span @teacher.display_name, :style => "font-size:100%" 
                  },
                  "Teaching Load"
    end
  end

  def term_change_link
    if params[:term]
      p "You are setting classes for next term. If you want to work on #{@teacher.display_name}&#39;s classes for the current term, click #{link_to 'here', edit_teaching_load_path(@teacher)}.", :style => 'clear:both'
   elsif @school.terms.count > 1
     p "You are setting classes for the current term. If you want to work on #{@teacher.display_name}&#39;s classes for next term, click #{link_to 'here', new_teaching_load_path(@teacher, :term => 'future')}."
    end
  end

  def title
    "#{@page_h1} | #{title_suffix}"
  end

  def title_suffix
    current_user.admin?? 'Teachers' : 'Sections'
  end

  def whose
    "#{@teacher.display_name}&#39;s " if current_user.admin?
  end

  def whose_class_list
    @teacher == current_user ? 'Your class list' : "The class list for #{@teacher.display_name}"
  end

end
