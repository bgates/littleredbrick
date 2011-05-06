require 'test_helper'
require 'helper_test_helper'

class ApplicationHelperTest < ActionView::TestCase

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_assignment_link_assignment
    stub_assignment
    stub_section
    assert_equal(assignment_link(@a),
                 link_to(1, section_assignment_path(@section, 'id'),
                         :title => "Click to see more information on 'A', including student scores"))
  end

  def test_assignment_link_grade
    stub_assignment
    stub_section
    g = stub(:assignment => @a)
    assert_equal(assignment_link(@a),
                 link_to(1, section_assignment_path(2, 'id'),
                         :title => "Click to see more information on 'A', including student scores"))
  end

  def test_assignment_link_for_student
    self.stubs(:current_user).returns Student.new
    stub_assignment
    assert_equal(assignment_link(@a),
                 link_to(1, student_assignment_path(2, 'id'),
                         :title => 'A'))
  end

  def test_assignment_page_range
    params[:first], params[:last] = 1, 10
    assert_equal(assignment_page_range, 'Assignments 1-10')
  end

  def test_absence_codes
    stub_school
    assert_equal(absence_code(@absence), 'T')
  end

  def test_absence_name
    stub_school
    assert_equal(absence_name(@absence), 'Tardy')
  end

  def test_limit_nav_size
    clear_link = li(link_to('12characters', home_path, :title => 'extra'), :style => 'clear: left;')
    nav = link * 6
    limited = limit_visible_characters(nav)
    assert @two_lines
    assert_equal(limited, link * 5 + clear_link)
  end

  def test_leave_nav_same_size
    nav = link * 5
    limited = limit_visible_characters nav
    assert_equal(limited, nav)
    assert !@two_lines
  end

  def test_last_assignment_link
    stub_section
    assignment = stub(:title => 'assignment', :id => 'id',
                      :new_record? => false)
    @section.stub_path('assignments._last').returns assignment
    @test_user.stubs(:may_see?).returns true
    result = link_to 'assignment',
                     section_assignment_path(@section, assignment)
    assert_equal last_assignment_link(@section), result
  end

  def test_no_last_assignment_link
    stub_section
    @section.stub_path('assignments._last').returns stub(:new_record? => true)
    assert_equal(last_assignment_link(@section), 'N/A')
  end

  def test_last_assignment_grade
    stub_section
    @section.stub_path('assignments._last').returns assignment = stub
    assignment.stubs(:id).returns 'id'
    other = stub(:assignment_id => nil)
    grades = [grade = stub(:assignment_id => 'id'), other]
    more_grades = [other, other_grade = stub(:assignment_id => 'id')]
    @rbes = [stub(:grades => grades), stub(:grades => more_grades)]
    assignment.expects(:average_pct).with([grade, other_grade]).returns 90.05
    assert_equal(last_assignment_grade(@section), '90.1')
  end

  def test_link_by_user
    self.stubs(:current_user).returns Student.new
    stub_section
    @assignment = stub(:category => 'homework')
    @mp_position = 2
    assert_equal(link_by_user,
                 student_assignments_path(@section,
                                          :cat => ['homework'],
                                          :mp => [2]))
  end

  def test_next_page
    params[:controller] = 'front_page'
    params[:action] = 'home'
    collection = stub(:current_page => stub(:next => 'next'),
                      :total_pages => 2)
    assert_equal(next_page(collection),
                 p(link_to('Next page', home_path(:page => 'next')),
                   :style => 'float:right;'))
  end

  def test_pagination
    collection = mock(:total_pages => 2)
    paginate_params = { :inner_window => 10, :next_label => 'next',
                        :prev_label => 'previous', :params => {
                          :discussable_type => nil,
                          :discussable_id => nil }}
    self.expects(:will_paginate).with(collection, paginate_params).returns 'PAGINATE'
    assert_equal(pagination(collection),
                 p('Pages'.html_safe + strong('PAGINATE')))
  end

  def test_pie
    distribution = { :a => 1, :b => 2, :c => 3 }
    assert_equal(google_chart("cht=p&chf=bg,s,ffffff00&chco=0085ff,bddfff,8fa8bf&chs=200x64&chd=t:1,2,3&chdl=a|b|c"), pie_chart(distribution))
  end

  def test_progression
    progression = [{ :grade => 10 }, { :grade => 1.07 }]
    assert_equal(google_chart("cht=lc&chd=t:10.0,1.1&chs=300x130&chco=66AEBD&chf=c,s,eeeeee&chxt=y&chg=1000,20,1,0"), progression_graph(progression))
  end

  def test_section_title
    self.stubs(:current_page?).returns false
    department = stub(:to_param => 'dept', :name => 'Dept')
    subject = stub(:to_param => 'sub', :name => 'Sub')
    section = stub(:time => 1, :department => department,
                   :subject => subject, :to_param => 'section',
                   :name => 'math')
    params[:section_id] = 'dept'
    dlink = link_to 'Dept', department_subjects_path(department), :title => "Click to view enrollment information for subjects in the Dept department"
    slink = link_to 'Sub', department_subject_path(department, subject), :title => "Click to see an overview of every section of Sub"
    link = link_to 1, section_path(section), :title => 'Click to see information on this math class'
    result = h2 [dlink, slink, link].join(arrow).html_safe
    assert_equal(result, section_title(section))
  end

  def test_teacher_page_link
    @test_user.expects(:may_see?).returns true
    stub_section
    @section.stubs(:teacher).returns teacher = stub(:display_name => 'mr teacher', :to_param => 'tchr')
    result = link_to 'mr teacher', teacher_path(teacher), :title => "Click to see an overview of mr teacher&#39;s classes".html_safe
    assert_equal(result, teacher_page_link)
  end

  def test_department_link
    @test_user.stubs(:admin?).returns false
    params[:section_id] = 'section'
    assert_equal(department_subjects_path('department'),
                 section_department_path('section'))
  end
  protected

  def link
    li(link_to '12characters', home_path, :title => 'extra')
  end

  def params
    @params ||= {}
  end

  def stub_assignment
    @a = Assignment.new(:position => 1, :section_id => 2, :title => 'A')
    @a.stubs(:to_param).returns 'id'
  end

  def stub_school
    @school = School.new
    @absence = Absence.new(:code => 0)
  end

  def stub_section
    @section = Section.new
    @section.stubs(:id).returns 2
  end
end

