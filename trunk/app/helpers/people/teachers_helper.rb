module People::TeachersHelper

  def secondary_nav
    breadcrumbs teachers_front, nav_finish
  end

  def nav_finish
    case action_name
    when 'show'
      @teacher.display_name
    when 'edit', 'update'
      [teacher_link(@teacher), 'Edit' ]
    when 'logins'
      [teacher_link(@teacher), 'Login History']
    when 'new', 'create'
      'New Teacher'
    end
  end

  def teachers_front
    link_to 'Teachers', teachers_path unless action_name == 'index'
  end
                                   
  def index_header(type,lo,hi)
    index_schedule(type, lo, hi) +
    tr(%w(Name ID).map{|w| th w }.join.html_safe + index_periods(lo,hi))
  end

  def index_periods(lo, hi)
    (lo..hi).map{|n| th n }.join.html_safe unless lo.nil?
  end

  def index_schedule(type, lo, hi)
    unless lo.nil?
      tr(th(type, :colspan => 2) + th('Schedule', :colspan => (hi - lo + 1)))
    end
  end

  def login_and_password
    if params[:teacher][:authorization][:password] == @teacher.login
      "(both) <code>#{@teacher.login}</code>"
    else
      "<code>#{@teacher.login}</code> and <code>#{params[:teacher][:authorization][:password]}</code>"
    end
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      raw "#{@teacher.full_name} was added, and can log in with user name and password #{login_and_password}. #{teacher_limit}"
    end
  end

  def msg_head(type)
    type == :notice ? h2("Good News") : ''
  end

  def section_links(teacher, sections, lo, hi)
    if sections.blank?
      "<td colspan='#{lo.nil?? 1 : hi - lo + 1}' class='text'>#{link_to_if @prepped_for_assignments, 'Assign classes', new_teaching_load_path(teacher), :title => 'Click to set up classes for ' + teacher.display_name do 'You may assign classes here after you create the catalog' end}</td>".html_safe
    else
      links = ''
      if lo.nil?
        sections.each{|s| links += "<td>#{link_to s.name, section_url(s), :title => 'Click to see an overview of this ' + s.name + ' class'}</td>"}
      else
        lo.upto(hi) do |n|
          this_period = sections.select{|s| s.time == n.to_s}
          if this_period.empty?
            links += td 'Prep'
          else
            links += '<td>' + this_period.collect{|s| "#{link_to s.name, section_url(s), :title => 'Click to see an overview of this ' + s.name + ' class'}"}.join('<br/>') + '</td>'
          end
        end
      end
      links.html_safe
    end
  end

  def section_list(teacher, sections,lo,hi)
    if sections.blank?
      td link_to('Assign classes', 
                 new_teaching_load_path(teacher, :term => 'future'),
                 :title => "Click to set up #{teacher.display_name}&#39;s classes for next term".html_safe), 
                 :colspan => (lo.nil?? 1 : hi - lo + 1), 
                 :class => 'text'
    else
      list = ''
      if lo.nil?
        sections.each{|s| list += td(s.name)}
      else
        lo.upto(hi) do |n|
          this_period = sections.select{|s| s.time == n.to_s}
          if this_period.empty?
            list += td 'Prep'
          else
            list += td this_period.collect{|s| "#{s.name}"}.join('<br/>') 
          end
        end
      end
      list.html_safe
    end
  end

  def teacher_limit
    teacher_limit_notice unless @school.may_add_more_teachers?
  end

  def title
    "#{@page_h1}#{title_suffix}"
  end

  def title_suffix
    ' | Teachers' unless action_name == 'index'
  end

  def gradebook_link(section)
    if current_user.id == section.teacher_id
      link_to section.name, section_gradebook_path(section), :title => "Click to see the gradebook for #{section.name}".html_safe
    else
      section_link(section).html_safe
    end
  end

  def term_link
    if @school.terms.count > 1
      present, other, term = params[:term].blank?? ['current', 'next', 'future'] : ['next', 'current', nil]
      "<h3>Term</h3><p>These are the schedules for the #{present} term. Click to see schedules for the #{link_to other, teachers_url(:term => term)} term.</p>".html_safe
    end
  end

  def next_assignment(assignment)
    if assignment
      "#{assignment.date_due} (#{assignment.point_value})"
    else
      "No future assignments"
    end
  end

  def last_assignment(assignment)
    if assignment
      "Due #{assignment.date_due} (Avg Score #{assignment.average_pct})"
    else
      "None in this marking period"
    end
  end

  def schedule_or_teacher_link(teacher)
    link_to_if @prepped_for_assignments, 
    "#{teacher.last_name}, #{teacher.title} #{teacher.first_name}",
    new_teaching_load_path(teacher), :title => 
    "Click to set up classes for #{teacher.display_name}".html_safe do
      "#{teacher.last_name}, #{teacher.title}, #{teacher.first_name}"
    end
  end

  def section_title(section)
    if current_user.teaches?(section)
      ("<h2>#{link_to(section.name_and_time, section_gradebook_path(section), :title => 'Click to see the gradebook for ' + section.name_and_time)}</h2>" +
      "<h3>#{section_link(section, 'Class Details')}</h3>").html_safe
    else
      "<h2>#{section.name_and_time}</h2><h3>#{section_link(section, 'Class Details')}</h3>".html_safe
    end
  end

end
