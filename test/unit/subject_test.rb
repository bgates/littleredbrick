require 'test_helper'

class SubjectTest < Test::Unit::TestCase

  def test_enrollment
    @subject = Subject.new
    @subject.expects(:sections).returns([mock(:enrollment => 20), mock(:enrollment => 30)])
    assert_equal 50, @subject.enrollment
  end
end

