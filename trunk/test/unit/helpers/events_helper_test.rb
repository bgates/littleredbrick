require 'test_helper'
require 'helper_test_helper'

class EventsHelperTest < ActionView::TestCase

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_class_for
    @sections = [stub(:id => 1), stub(:id => 2)]
    result = "class1 assignment_1"
    assignment = Assignment.new(:section_id => 1)
    assert_equal(class_for(assignment), result)
    event = Event.new(:invitable_type => 'User')
    assert_equal('personal event_user', class_for(event))
    event.invitable_type = 'School'
    assert_equal('schoolwide event_school', class_for(event))
    event.invitable_type, event.invitable_id = 'Section', 2
    assert_equal('class2 event_2', class_for(event))
    event.invitable_type = 'Staff'
    assert_equal('event_staff', class_for(event))
  end

  def test_edit_path
    e = Grade.new(:section_id => 1, :assignment_id => 2)
    result = edit_section_assignment_path(:section_id => 1, :id => 2)
    assert_equal(result, edit_path_check_for_grade(e))

    e = Assignment.new(:section_id => 1)
    e.stubs(:to_param).returns '2'
    assert_equal(result, edit_path_check_for_grade(e))

    e = Event.new
    e.stubs(:to_param).returns 'id'
    assert_equal(edit_event_path(e), edit_path_check_for_grade(e))
  end

  def test_event_assignment_link
    event = stub(:title => 'title', :to_param => 'id', :invitable_type => 'School')
    event.stub_path('section.name').returns 'name'
    result = link_to 'title', assignment_as_event_path(event), :title => 'name : title', :class => 'schoolwide event_school'
    assert_equal(result, event_assignment_link(event, nil))
  end

  def test_id_only
    assignment = stub
    assignment.stub_path('section.name_and_time').returns 'result'
    assignments = [assignment, :etc, :etc]
    assert_equal('result', id_only(assignments, :etc, :etc))
  end

  def test_truncated_span
    assert_equal('word' * 9, truncated_span('word' * 9, false))
  end

  def test_truncated_student
    event = stub
    event.stub_path('rollbook_entry.student.full_name').returns 'name'
    assert_equal('name', truncated_student(event, true))

    event.stub_path('assignment.title').returns 'title'
    assert_equal('title(name)', truncated_student(event, false))
  end
end

