require 'test_helper'

class LoginTest < Test::Unit::TestCase

  def test_stringify
    @login = Login.create
    assert_equal "#{@login}", @login.created_at.strftime("%b %d %Y")
  end
end

