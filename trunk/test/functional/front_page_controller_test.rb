require 'test_helper'

class FrontPageControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = @request.session[:user] = :exists
    @school = schools(:default)
  end

  def test_index_teacher_classless
    prepare_teacher([])
    assert flash[:notice] =~ /set/
    assert_template 'teacher'
  end

  def test_index_teacher_empty_classes
    prepare_teacher([Section.new])
    assert flash[:notice] =~ /enroll/
  end

  def test_index_teacher_full_classes
    prepare_teacher([Section.new(:enrollment => 1)])
    assert flash[:notice] =~ /assignment/
  end
  
  def test_index_teacher_setup
    prepare_index :teacher
    @user.expects(:admin?).returns(true)
    get :home
    assert_template('setup')
  end

  def test_index_staffer_setup
    prepare_index :staffer
    get :home
    assert_template('setup')
  end

  def test_index_staffer
    prepare_index :staffer
    @controller.expects(:setup_required?).returns(false)
    get :home
    assert_template('administrator')
  end

  def test_index_student
    prepare_index :student
    get :home
    assert_template('student')
  end

  def test_index_parent
    prepare_index :parent
    @request.session[:child] = 'child'
    @user.children.expects('find').returns(@child = Student.new)
    @child.expects(:all_events).returns([])
    get :home
    assert_template('parent')
  end

  def test_admin
    prepare_index :staffer
    @school.expects(:terms).returns [stub(:to_param => 'term')]
    get :admin
    assert_response :success
  end

  def test_initial
    @request.session[:initial] = true
    prepare_index(:staffer)
    @school.expects(:mark_as_setup!)
    @school.expects(:has_not_been_setup?).returns(false)
    get :home, :setup => true
    assert @request.session[:initial].nil?
  end
private

  def prepare_index(klass)
    @user = Factory.create klass, :school => @school
    @user.stubs(:all_events).returns []
    @user.stubs(:recent_posts_of_interest).returns []
    @controller.stubs(:set_user).returns(@user)
  end

  def prepare_teacher(sections)
    prepare_index :teacher
    @user.expects(:logins).returns([:first_login])
    sections.each{ |s| s.stubs(:to_param).returns 'id' }
    @user.stub_path('sections.includes').returns(sections)
    @controller.stubs(:prepare_section_data).returns(true)
    get :home
  end
end
