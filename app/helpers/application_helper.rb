require 'digest/md5'
module ApplicationHelper
include ChartHelper, NavHelper, BifurcatedRoutesHelper

  def absence_code(absence)
    @school.absence_codes(true)[absence.code]
  end

  def absence_name(absence)
    @school.absence_codes(false)[absence.code]
  end

  def action_name
    controller.action_name
  end

  def admin_front_link
    link_to 'Administrative Tasks', admin_home_path, 
            :title => 'Click to return to the overview of administrative functions'
  end

  def admins_link
    link_to_unless current_page?(administrators_path) && @admin.nil?, 
                   'Administrators', administrators_path, 
                   :title => 'Click to view and edit administrator accounts'
  end

  def ajax_spinner_for(id, spinner="indicator_16.gif")
    image_tag spinner, 
    style:"display:none; vertical-align:middle;", id:"#{id.to_s}_spinner"
  end

  def assignment_link(grade_or_assignment)
    assignment = grade_or_assignment.is_a?(Assignment) ? 
                 grade_or_assignment : grade_or_assignment.assignment
    if (current_user.is_a?(Parent) || current_user.is_a?(Student))
      link_to assignment.position, 
              student_assignment_path(assignment.section_id, assignment),
              :title => assignment.title
    else
      link_to assignment.position, 
              section_assignment_path(@section, assignment),
              :title => "Click to see more information on '#{assignment.title}', including student scores"
    end
  end

  def assignment_page_mp_or_dates
    if assignment_page_range == 'Assignments'   
      begin
        "(#{params[:start].to_date.strftime("%b %d")}-
          #{params[:finish].to_date.strftime("%b %d")})" 
      rescue
        params[:mp].blank?? "(Marking Period #{@mp})" : 
                        "(Marking Period #{params[:mp].to_a.to_sentence})" 
      end
    end
  end
  
  def assignment_page_range
    if (params[:first].blank? || params[:last].blank?)
      'Assignments' 
    else
      "Assignments #{params[:first]}-#{params[:last]}"
    end
  end

  def assignment_page_title
    category = params[:cat].map(&:capitalize).to_sentence if params[:cat]
    "#{category} #{assignment_page_range} for #{@section.name} #{assignment_page_mp_or_dates}"
  end

  def arrow
    span "&rarr;".html_safe, :class => "arrow"
  end

  def normal_text(txt)
    span txt, :class => 'norm'
  end

  def department_link_unless_current(department)
    link_to_unless_current department.name, department_subjects_path(department),
                   :title => "Click to view enrollment information for subjects in the #{department.name} department"
  end

  def filler_row(var, cols)
    if var.length < 11
     tr td('&nbsp;'.html_safe, colspan:cols, style:"height:#{13 - var.length}em"), 
        class:"doNotSort"
    end
  end

  def footer
    "&#169; 2008-11 Little#{link_to 'Red', 'http://www.littleredbrick.com', 
                                 class:'company'}Brick"
  end

  def grade_with_precision(grade)
    number_with_precision(grade, :precision => 1) rescue 'N/A'
  end

  def grade_values
    @grades.values.reject{|g| g == '-' }.map{|g| g.percent(@assignment) }
  end

  def gradebook_page_link
    link_to 'Gradebook', section_gradebook_path(@section), 
      :title => 'Click to add assignments and grades for the class' if current_user.teaches?(@section)
  end

  def his_or_your
    current_user == @teacher ? 'your' : "#{@teacher.display_name}&#39;s"
  end

  def initial
    div "#{link_to 'Return', home_path} to the home page to see the full list of what must be done to set up your school.".html_safe, :class => "notice" if session[:initial]
  end

  def last_assignment_link(section)
    if !section.assignments._last.new_record? && current_user.may_see?(section)
      link_to section.assignments._last.title,  
              section_assignment_path(section, section.assignments._last) 
    else
      'N/A'.html_safe
    end
  end

  def last_assignment_grade(section)
    a = section.assignments._last
    grades = if @rbes.nil?
               a.grades 
             else 
               @rbes.map{|r| r.grades.detect{|g|g.assignment_id == a.id}} 
             end
    grade_with_precision(a.average_pct(grades)) 
  end

  def link_by_user
    if current_user.is_a?(Teacher) || current_user.is_a?(Staffer)
      section_assignments_path(@section, :cat => [@assignment.category], :mp => [@mp_position])
    else
      student_assignments_path(@section, :cat => [@assignment.category], :mp => [@mp_position])
    end
  end

  def link_to_term
    link_to 'Term', term_path(@term), :title => 'Click to return to the term page'
  end

  def mark_of_the_beast;end

  def marking_period_links
    (1..@n_mps).map do |n|
      link_to_unless n == @mp_position, n, {:marking_period => n}, 
        {:title => "Click to see grades for marking period #{n}"} do
        span n, :title => "currently viewing grades for marking period #{n}", 
                :style => "font-size:1.3em"  
        end
    end.join.html_safe
  end

  def msg_head(type)
    type == :notice ? h2("Good News") : ''
  end

  def next_page collection
    unless only_page? collection
      p link_to("Next page"[], next_params(collection)), 
        :style => "float:right;"
    end
  end

  def next_params collection
    params.merge(:page => collection.current_page.next)
  end

  def notice_or_error
    if !flash[:notice].nil?
      div sanitize(flash[:notice], :attributes => %w(id class style href mailto)), 
          :id => 'notice'
    elsif !flash[:error].nil?
      div sanitize(flash[:error], :attributes => %w(id class style href)), 
          :id => 'error'
    end
  end

  def only_page? collection
    [0, collection.current_page].include? collection.total_pages 
  end
   
  def pagination collection
    if collection.total_pages > 1
      p('Pages'[:pages_title].html_safe + 
      strong(will_paginate(collection, :inner_window => 10, 
                                       :next_label => "next"[], 
                                       :prev_label => "previous"[], 
                                       :params => { 
        :discussable_type => nil, :discussable_id => nil })))
    end
  end

  def point_value(total)
  "#{@assignment.point_value} / #{total} 
   (#{number_with_precision(100 * @assignment.point_value/total.to_f, 
                            :precision => 0) rescue 'N/A' })%)" 
  end

  def rangify(range)
    return "< #{range.last}" if range.first ==  -1.0 / 0
    return "> #{range.first}" if range.last == 1.0 / 0
    "#{range.first} &ndash; #{range.last - 1}".html_safe
  end

  def rbe_link(student, section, text = nil, condition = true)
    text ||= "#{student.last_name}, #{student.first_name}"
    link_to_if condition, text, rbe_path(student, section), 
      :title => "Click to see #{student.first_name}&#39;s performance in #{section.name}".html_safe
  end

  def return_link_by_user
    "#{return_link_for_teacher}#{section_link(@section, 'Section')}" 
  end

  def return_link_for_teacher
    if current_user.teaches?(@section) 
      "#{link_to 'Gradebook', section_gradebook_path(@section), 
        :title => 'Click to see the gradebook for this class'} | "
    end
  end

  def sections_front
    link_to 'Sections', sections_path, :title => 'Click to see an overview of all of your classes' unless current_user.admin?
  end

  def section_link(section, text = nil, conditional = true, options = {})
    text ||= section.name
    link_to_if conditional, text, section_path(section), 
               options.merge(:title => "Click to see the class overview for #{section.name_and_time}")
  end

  def section_time
    "(Period #{@section.time})" if @section.time
  end

  def section_student_link(section, student, text = nil, which = nil)
    text ||= student.last_first
    which ||= section.name
    link_to text, section_enrollment_path(section, student),
            :title => "Click to see more information about #{student.first_name}&#39;s performance in #{which}".html_safe
  end

  def section_page_link
    link_to_if current_user.may_see?(@section), 
      @section.name_and_time(false), section_path(@section), 
      :title => "Click to see information on the #{@section.name} class" do
        normal_text @section.name_and_time(false) 
      end
  end

  def section_title(section)
    unless @section
      link_text = section.time.nil?? 'View section' : section.time
      h2([department_link_unless_current(section.department),
          subject_link(section.subject, section.department),
          link_to(link_text, section_path(section), 
                  :title => "Click to see information on this #{section.name} class")].join(arrow).html_safe)
    end
  end

  def subject_link(subject, department = nil, text = nil)
    department ||= subject.department_id
    text ||= subject.name
    link_to text, department_subject_path(department, subject), 
    :title => "Click to see an overview of every section of #{subject.name}"
  end

  def submit_tag(value = "Save Changes"[], options={} )
    or_option = options.delete(:or)
    return super + 
           span("or #{or_option}", :class => 'button_or') if or_option
    super
  end

  def teacher_limit_notice
    raw "You have reached the limit on the number of teacher accounts you are allowed under your current subscription plan. If you need to add more, please contact us at #{mail_to 'support@littleredbrick.com', 'support@littleredbrick.com', :encode => :hex} to upgrade."
  end

  def teacher_link(teacher, conditional = true, text = nil, &block)
    text ||= teacher.display_name
    link_to_if conditional, text, teacher_path(teacher), 
      :title => "Click to see an overview of #{teacher.display_name}&#39;s classes".html_safe, &block
  end

  def teacher_or_gradebook
    if current_user.teaches?(@section)
      link_to 'Gradebook', section_gradebook_path(@section)
    else
      teacher_link(@teacher)
    end
  end

  def teacher_page_link
    unless current_user.teaches?(@section)
      teacher_link(@section.teacher, 
                   current_user.may_see?(@section.teacher)) do
                     normal_text @section.teacher.display_name
                   end
    end
  end

  def teacher_section_gradebook_links
    [sections_front, teachers_front, teacher_page_link, section_page_link, 
     gradebook_page_link]
  end

  def teachers
    "#{@teacher.display_name}&#39;s " if current_user.admin?
  end

  def teachers_front
    link_to 'Teachers', teachers_path if current_user.admin?
  end

  def term_link
    if @school.terms.count > 1
      present, other, term = params[:term].blank?? ['next', 'current', nil] : ['current', 'next', 'future']
      h3('Term') + 
      p("These are the schedules for the #{present} term. Click to see 
        schedules for the #{link_to other, students_url(:term => term)} 
        term.")
    end
  end

  def term_name(term)
    "#{term.start_date.strftime('%b %d')}&#151;
     #{term.end_date.strftime('%b %d')}".html_safe
  end

  def title
    if action_name == 'index'
      @title = "#{controller.controller_name.humanize.titleize}"
    else
      @title = "#{action_name.humanize.titleize} #{controller.controller_name.humanize.titleize.singularize}"
    end
  end

  [:div, :tr, :td, :th, :span, :li, :h2, :h3, :p, :ol, :ul, :strong].each do |element|
    define_method(element) do |content, options = {}|
      content_tag element, content, options
    end
  end
end
