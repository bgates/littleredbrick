require 'test_helper'
require 'helper_test_helper'

class TeachingLoadHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_track_selector
    @tracks = [stub(:id => 1, :position => 1), stub(:id => 2, :position => 2)]
    s = ActionView::Base.default_form_builder.new('section', Section.new, self, {}, {})
    assert conditional_track_selector(s) =~ /\[track_id\]/
  end

  def test_nav
    @teacher = stub(:display_name => 'mr teacher', :to_param => 'id')
    @sections = [Section.new]
    assert secondary_nav =~ /mr teacher/
  end

  def test_change_term
    params[:term] = 'future'
    @teacher = stub(:display_name => 'mr teacher', :to_param => 'id')
    assert term_change_link =~ /current term,/

    params[:term] = nil
    @school = School.new
    assert_nil term_change_link

    @school.terms.expects(:count).returns 2
    assert term_change_link =~ /future/
  end

  protected

    def params
      @params ||= {}
    end
end

