require 'test_helper'
require 'helper_test_helper'

class People::TeachersHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_gradebook_link
    section = stub(:to_param => 'id', :name => 'algebra', :teacher_id => nil)
    result = link_to 'algebra', section_gradebook_path(section),
             :title => 'Click to see the gradebook for algebra'
    assert_equal(result, gradebook_link(section))
  end

  def test_gradebook_link_two
    section = stub(:to_param => 'id', :name => 'algebra', :teacher_id => 1,
                   :name_and_time => 'period 3 French')
    assert_equal(section_link(section), gradebook_link(section))
  end

  def test_next_assignment
    assignment = mock(:date_due => Date.today, :point_value => 5)
    assert_equal(next_assignment(assignment), "#{Date.today} (5)")

    assert_equal(next_assignment(nil), 'No future assignments')
  end

  def test_last_assignment
    assignment = mock(:date_due => Date.today, :average_pct => 90)
    assert_equal(last_assignment(assignment), "Due #{Date.today} (Avg Score 90)")

    assert_equal(last_assignment(nil), 'None in this marking period')
  end

  def test_section_title
    section = Section.new
    @test_user.expects(:teaches?).returns false
    section.stubs(:name_and_time).returns 'Period 3 French'
    section.stubs(:to_param).returns 'id'

    assert section_title(section) =~ /<h2>Period 3/
  end
end

