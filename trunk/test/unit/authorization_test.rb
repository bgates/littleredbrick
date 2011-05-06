require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase

  def test_reset
    @user = User.new(:first_name => 'Test', :last_name => 'Case')
    @auth = @user.build_authorization
    @user.reset!
    assert_equal 'testcase', @auth.login
  end

  def test_fail_authentication_for_completeness
    assert !Authorization.authenticate('no such', 'user', 1)
  end

  def test_reset_login_key
    @auth = Authorization.new(:crypted_password => 'crypt', :login_key => 'initial')
    @auth.expects(:save!).returns(true)
    assert @auth.reset_login_key! != 'initial'
  end

  def test_defaults
    u = User.new(:first_name => 'bob ', :last_name => 'spaceless')
    u.valid?
    @auth = u.authorization
    @auth.add_default_attributes(u)
    assert_equal 'bobspaceless', @auth.login
  end
end

