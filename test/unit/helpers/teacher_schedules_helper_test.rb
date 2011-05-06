require 'test_helper'
require 'helper_test_helper'

class Upload::TeacherSchedulesHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_term_selector
    @school = stub
    @school.stub_path('terms.count').returns 2
    assert term_selector =~ /#{check_box_tag('current', true)}/
  end

  protected

    def params
      @params ||= {}
    end
end

