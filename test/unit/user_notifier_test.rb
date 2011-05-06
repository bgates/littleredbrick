require 'test_helper'

class UserNotifierTest < ActiveSupport::TestCase
  CHARSET = "utf-8"

  def setup
    @school = School.new(:domain_name => 'test')
    @user = User.new(:email => 'new@school.edu')
  end

  def test_password_bypass
    @auth = @user.build_authorization
    @auth.expects(:bypass_code).returns('secret word')
    @email = UserNotifier.password_bypass(@school, @user).deliver
    assert_match 'http://test.littleredbrick.com/bypass/secret word', @email.encoded
    assert_equal %w(new@school.edu), @email.to
  end

  def test_creation_notifier
    @expected = UserNotifier.school_creation_notification(@school, @user)
    assert_equal 'New school', @expected.subject
    assert_equal %w(bmathg@yahoo.com), @expected.to
  end

  def test_welcome
    @email = UserNotifier.welcome_email(@school, @user).deliver
    assert_equal 'Thanks for signing up with LittleRedBrick!', @email.subject
    assert_match 'http://test.littleredbrick.com', @email.encoded
    assert_equal %w(new@school.edu), @email.to
  end
end

