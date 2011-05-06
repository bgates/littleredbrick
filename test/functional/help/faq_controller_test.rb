require 'test_helper'

class Help::FaqControllerTest < ActionController::TestCase
      
  def setup
    generic_setup Staffer
  end

  def test_index
    get :display
    assert_template('index')
  end

  def test_nonindex
    get :display, :action => 'accessibility'
    assert_template 'accessibility'
  end
end
