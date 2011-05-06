require 'test_helper'
require 'helper_test_helper'

class FrontPageHelperTest < ActionView::TestCase

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_discussable_for
    topic = stub
    topic.stub_path('last_post.discussable_type').returns 'staff'
    school = discussable_for(topic)
    assert school.is_a?(School)
    assert_equal('staff', school.type)
  end

  def test_discussable_for_section
    post = stub(:discussable_type => 'Section', :discussable_id => 1)
    topic = Topic.new
    topic.stubs(:last_post).returns post
    Section.expects(:find).with(1).returns section = Section.new
    section.stubs(:id).returns 1
    assert_equal(section, discussable_for(topic))
  end

  def test_completion_notice
    @all_enrolled = true
    self.expects(:completion_notice).returns 'all done'
    assert_equal('all done', conditional_class_assignment_link)
  end
end

