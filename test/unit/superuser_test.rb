require 'test_helper'

class SuperuserTest < ActiveSupport::TestCase

  def test_superuser
    user = Superuser.create(:first_name => 'Bruce', :last_name => 'Wayne')
    assert user.admin?
    assert_equal user.display_name, 'Bruce (Tech Support)'
    assert user.may_see? :whatever_this_is_called_for
  end

  def test_superuser_forums
    user = Superuser.new
    school = School.new
    school.type = 'parents'
    assert user.may_access_forum_for? school
    assert user.may_create_forum_for? school
  end
end
