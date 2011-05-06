require 'test_helper'
require 'helper_test_helper'

class AccountUploadHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
    default_user = User.new(:first_name => 'Test', :last_name => 'User')
    default_user.build_authorization(:login => 'testuser')
    @saveable = [default_user]
  end

  def test_msg
    @type = 'users'
    assert_equal msg(true), "<h2>Good News</h2><p>1 users were saved. The default login and password for each account is simply the user&#39;s full name. For instance, Test User has login and password (both) <code>testuser</code>, which s/he will be prompted to change on first log in to keep the account secure.</p> "
  end

  def test_mailto_in_msg
    @type = 'teachers'
    @school = mock(:may_add_more_teachers? => false)
    mail = mail_to('support@littleredbrick.com', 'support@littleredbrick.com', :encode => 'hex')
    assert msg =~ /#{mail}/
  end
end

