module People::StudentsHelper

  def absence_calendar(year, month, section, absences)
    calendar({:year => year, :month => month, :table_class => 'sideCalendar', :other_month_class => 'outOfMonth'}) do |d|
      cell_text = ""
      cell_attrs = {:class => 'day'}
      if current_user.teaches?(section)
        cell_text << "#{link_to d.mday, section_attendance_path(section, d), :title => 'Click to see class attendance information for ' + d.strftime("%B %d")}"
      else
        cell_text << "#{d.mday}"
      end
      if absences && a = absences.detect{|a|a.date == d}
        cell_text << " <span class=\"absence\" title=\"#{absence_name(a)}\">#{absence_code(a)}</span>"
        cell_attrs[:class] = 'specialDay'
      end
      [cell_text, cell_attrs]
    end
  end

  def absence_summary(absences)
    day, period = Absence.summary(@student.sections, absences)
    "#{absence_sentence(day, 'day')}<br/>#{absence_sentence(period, 'period')}".html_safe
  end
  
  def absence_sentence(time, word)
    time.map{|code, n| "#{pluralize(n, word)} of #{@school.absence_codes(false)[code]}"}.to_sentence
  end

  def attendance_list(student)
    list = ''
    if @low_period.nil?
      student.rollbook_entries.select{|rbe|rbe.section.current}.each{|rbe| list += "<td title=\"#{rbe.section.name}\">#{rbe.absence_on(@date, @school)}</td>"}
    else
      sections = user.rollbook_entries.group_by{|rbe|rbe.section.time.to_i}
      @low_period.upto(@high_period) do |n|
        if sections[n].nil? || sections[n].all?{|rbe| !rbe.section.current}
          list << td('&nbsp;') 
        else
          list += td sections[n].reject{|rbe| !rbe.section.current}.collect{|rbe| "#{rbe.absence_on(@date, @school)}"}.join.strip 
        end
      end
    end
    list
  end

  def default_pwd_used
    (params[:student][:authorization][:password].blank? || params[:student][:authorization][:password] == (params[:student][:first_name] + params[:student][:last_name]).downcase) ? 'and password (both) ' : ''
  end

  def last_crumb(*link_and_text)
    breadcrumbs students_front, link_and_text
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p "#{@student.full_name} was added, and can log in with user name #{default_pwd_used}#{@student.login}. Accounts for #{@student.first_name}&#39;s parents were created with username/password <code>#{@student.login}_mother</code> (for #{@student.first_name}&#39;s mother) and <code>#{@student.login}_father</code> (father)."
    when 'destroy'
      if type == :notice
        p "#{@student.display_name} was removed from the system. All of that student's class records have been destroyed as well."
      else
        p "Something went wrong, and #{@student.display_name} was not deleted."
      end
    when 'update'
      p "#{@student.first_name} was updated."
    end
  end

  def msg_head(type)
    type == :notice ? h2('Good News') : h2('Bad News')
  end
  
  def secondary_nav
    case action_name
    when 'index'
    when 'show'
      last_crumb @student.full_name
    when 'edit', 'update'
      last_crumb student_link, 'Edit'
    when 'new', 'create'
      last_crumb 'New Student'
    else
      last_crumb student_link, action_name.titleize
    end
  end

  def student_link
    link_to @student.full_name, student_path(@student), :title => "Click to see an overview of #{@student.first_name}&#39;s academic performance".html_safe
  end
  
  def students_front
    link_to 'Students', students_path
  end

  def index_header(type,lo,hi)
    index_schedule(type, lo, hi) +
    tr(%w(Name ID Grade).map{|w| th w }.join.html_safe + index_periods(lo,hi))
  end

  def index_periods(lo, hi)
    (lo..hi).map{|n| th n }.join.html_safe unless lo.nil?
  end

  def index_schedule(type, lo, hi)
    unless lo.nil?
      tr(th(type, :colspan => 3) + th('Schedule', :colspan => (hi - lo + 1)))
    end
  end

  def parent_logins(user)
    if user.last_login
      "<dt>#{user.display_name}</dt><dd> #{user.logins.size} logins (Last at #{user.last_login.strftime("%I:%M%p %A %B %d")})</dd>" 
    elsif user.last_name =~ /_/   
      p "#{@student.first_name}\'s #{user.which_parent} has never logged in"
    else
      p "#{user.display_name} has never logged in"
    end
  end

  def student_logins(student)
    if student.last_login
      "<dd> #{student.logins.size} (Last at #{student.last_login.strftime("%I:%M%p %A %B %d")})</dd>"
    else
      p "#{student.first_name} has never logged in" 
    end
  end
  
  def section_title(section)
    h2([teacher_link(section.teacher, current_user.admin?),
        link_to_if(current_user.may_see?(section), 
                   section.name_and_time(false), section_path(section), 
                   :title => "See class-level data for #{@student.first_name}&#39;s #{section.name} class".html_safe),
        section_student_link(section, @student, @student.first_name)
       ].join(arrow).html_safe)
  end

  def section_links(user)
    links = ''
    if @low_period.nil?
      user.rollbook_entries.select{|rbe|rbe.section.current == @term}.each{|rbe| links += "<td>#{section_student_link(rbe.section, rbe.student, rbe.section.name)}</td>"}
    else
      sections = user.rollbook_entries.group_by{|rbe|rbe.section.time.to_i}
      @low_period.upto(@high_period) do |n|
        if sections[n].nil? || sections[n].all?{|rbe|rbe.section.current != @condition}
          links << td('Prep')
        else
          links += '<td>' + sections[n].reject{|rbe|rbe.section.current != @condition}.collect{|rbe| "#{section_student_link(rbe.section, user, rbe.section.name)}"}.join('<br/>') + '</td>'
        end
      end
    end
    links.html_safe
  end

  def section_list(user)
    list = ''
    if @low_period.nil?
      user.rollbook_entries.select{|rbe|rbe.section.current == @term}.each{|rbe| list += "<td>#{rbe.section.name}</td>"}
    else
      sections = user.rollbook_entries.group_by{|rbe|rbe.section.time.to_i}
      @low_period.upto(@high_period) do |n|
        if sections[n].nil? || sections[n].all?{|rbe|rbe.section.current != @condition}
          list << '<td>Prep</td>'
        else
          list += '<td>' + sections[n].reject{|rbe|rbe.section.current != @condition}.collect{|rbe| "#{rbe.section.name}"}.join('<br/>') + '</td>'
        end
      end
    end
    list
  end

  def teacher_or_your
    if current_user.admin?
      "the #{link_to "teacher page", teachers_path}, click on the class name,".html_safe 
    else
      "one of your #{link_to 'class pages', sections_path}".html_safe
    end
  end

  def title
    @page_h1 ? "#{@page_h1} | Students" : 'Students'
  end
end
