require 'test_helper'
require 'helper_test_helper'

class People::AdministratorsHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_add_teacher
    @school = mock(:may_add_more_teachers? => true)
    assert add_teacher =~ /If you are sure/
  end

  def test_dont_add_teacher
    @school = mock(:may_add_more_teachers? => false)
    assert_nil(add_teacher)
  end

  def test_new_link
    @teachers = []
    self.expects(:add_teacher).returns '[teacher link]'
    assert new_link_if_allowed =~ /No teacher/
  end

  def test_no_new_link
    @teachers = [:teacher]
    assert_nil(new_link_if_allowed)
  end
end

