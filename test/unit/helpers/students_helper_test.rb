require 'test_helper'
require 'helper_test_helper'

class People::StudentsHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_name
    @test_user.stubs(:admin?).returns false
    assert teacher_or_your =~ /one of your/
  end

  def test_no_parent_logins
    parent = mock(:last_login => nil, :display_name => 'mr parent',
                  :last_name => 'underscoreless')
    assert_equal(p('mr parent has never logged in'), parent_logins(parent))
  end

  def test_parent_login
    time = Time.now
    parent = mock(:display_name => 'mr parent', :logins => [1])
    parent.stubs(:last_login).returns time
    result = "<dt>mr parent</dt><dd> 1 logins (Last at #{time.strftime("%I:%M%p %A %B %d")})</dd>"
    assert_equal(result, parent_logins(parent))
  end

  def test_new_parent_no_logins
     @student = mock(:first_name => 'Kid')
     parent = mock(:last_login => nil, :last_name => 'new_parent',
                 :which_parent => 'father')
     result = p "Kid's father has never logged in"
     assert_equal(result, parent_logins(parent))
  end
end

