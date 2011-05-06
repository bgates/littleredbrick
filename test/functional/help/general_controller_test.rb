require 'test_helper'

class Help::GeneralControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns(true)
  end

  def test_action
    assert_routing 'help/admin', :controller => 'help/general', :action => 'display', :controller_name => 'admin'
    get :display, :controller_name => 'admin'
    assert_equal(assigns(:path), 'admin')
    assert_template('admin')
  end

  def test_initial
    session[:initial] = true
    get :display, :controller_name => 'setup'
    assert_select "h2", "Setup Task List"
  end

  def test_folder
    assert_routing 'help/discussions/forums', :controller => 'help/general', :action => 'display', :controller_name => 'discussions', :action_name => 'forums'
    get :display, :controller_name => 'discussions', :action_name => 'forums'
    assert_template('forums')
  end

  def test_folder_2
    get :display, :controller_name => :discussions, :action_name => 'topics'
    assert_response :success
  end
  
  def test_video_staffer
    generic_setup Staffer
    get :video, :id => 'tour'
    assert_equal(assigns(:video), 'intro')
  end

  def test_video_teacher_as_admin
    session[:admin] = true
    get :video, :id => 'other'
    assert_select "embed[src=?]", '/video/staffer/other.swf'
  end

  def test_video_teacher
    get :video, :id => 'other'
    assert_select "embed[src=?]", '/video/teacher/other.swf'
  end

  def test_video_student
    generic_setup Student
    get :video, :id => 'other'
    assert_select "embed[src=?]", '/video/file/other.swf'
  end

  def test_subject_menu
    get :display, :controller_name => 'subject_menu'
    assert_equal assigns(:path), 'subject_menu'
  end

  def test_video_menu_admin
    session[:admin] = true
    get :display, :controller_name => 'video_menu'
    assert_equal('video_menu_staffer', assigns(:path))
  end

  def test_video_menu_teacher
    get :display, :controller_name => 'video_menu'
    assert_equal('video_menu_teacher', assigns(:path))
  end
  
  def test_menu
    get :display
    assert_equal('index', assigns(:path))
  end

  def test_tour_new_teacher
    get :video, :id => 'tour'
    assert_equal('setup_new', assigns(:video))
  end

  def test_tour_empty_classes
    @user.sections.build
    get :video, :id => 'tour'
    assert_equal('setup_post_class', assigns(:video))
  end

  def test_tour_student
    generic_setup Student
    get :video, :id => 'tour'
    assert_equal('tour', assigns(:video))
  end
end
