require 'test_helper'

class People::ParentsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @school.stubs(:students).returns(@students = stub())
    @students.stubs(:find).returns(@student = Student.new(:first_name => 'child', :last_name => 'test'))
    @parents = [@parent = Parent.new(:first_name => 'test', :last_name => 'parent')]
    @parents.stubs(:find).returns(@parent)
    @parent.stubs(:to_param).returns 'id'
    @student.stubs(:parents).returns(@parents)  
  end

  def test_fail_login
    @controller.stubs(:authorized?).returns false
    get :edit, :student_id => :child, :id => @parent
    assert_redirected_to login_path
  end

  def test_edit
    get :edit, :student_id => :child, :id => @parent
    assert_response :success
  end

  def test_index
    @school.stubs(:parents).returns(stub(:paginate => @parents, :count => 2))
    @parents.expects(:total_pages).returns(1)
    @parent.stubs(:children).returns [Student.new]
    get :index
    assert_response :success
  end

  def test_parents
    get :index, :student_id => 1
    assert_template('student_index')
  end
  
  def test_update
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => []))
    @parent.expects(:update_attributes).returns(true)
    put :update, :student_id => :child, :id => @parent, :parent => {:title => 'Mrs'}
    assert_redirected_to student_url(@student)
  end

  def test_update_fail
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => []))
    @parent.expects(:update_attributes).returns(false)
    put :update, :student_id => :child, :id => @parent, :parent => {:title => 'Mrs'}
    assert_template 'edit'
  end

  def test_remove_child
    @parent.expects(:children).returns(stub(:delete => true))
    delete :destroy, :student_id => :child, :id => @parent, :remove => 1
    assert_redirected_to student_path(@student)
  end

  def test_destroy
    @parent.expects(:destroy).returns(true)
    delete :destroy, :student_id => :child, :id => @parent
    assert_redirected_to student_path(@student)
  end

  def test_create_blocked_duplicate_name
    @duplicate = Parent.new
    @duplicate.stubs(:children).returns([Student.new])
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => [@duplicate]))
    post :create, :student_id => :child, :parent => {:first_name => 'test', :last_name => 'parent'}
    assert_template('new')
  end

  def test_create_despite_duplicate_name
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => [@duplicate], :new => @parent))
    Student.stubs(:find).returns([Student.new(:first_name => 'test', :last_name => 'child')])
    #@parent.expects(:valid?).returns(true)
    post :create, :student_id => :child, :parent => {:first_name => 'test', :last_name => 'parent'}, :parent_id => 'new'
    assert_redirected_to student_path(@student)
  end

  def test_create_with_replace
    @school.expects(:parents).returns(stub(:find => @parent))
    Student.stubs(:find).returns([Student.new(:first_name => 'test', :last_name => 'child')])
    post :create, :student_id => :child, :parent => {:first_name => '', :last_name => ''}, :parent_id => 1
    assert_redirected_to student_path(@student)    
  end
  
  def test_update_blocked_duplicate_name
    @duplicate = Parent.new
    @duplicate.stubs(:children).returns([Student.new])
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => [@duplicate]))
    put :update, :student_id => :child, :id => @parent, :parent => {:first_name => 'test', :last_name => 'parent'}
    assert_template('edit')
  end

  def test_update_despite_duplicate_name
    @school.expects(:parents).returns(stub(:find_all_by_first_name_and_last_name => [Parent.new]))
    @parent.expects(:update_attributes).returns(true)
    put :update, :student_id => :child, :id => @parent, :parent => {:first_name => 'test', :last_name => 'parent'}, :replace => 'new'
    assert_redirected_to student_path(@student)
  end

  def test_show
    get :show, :student_id => :child, :id => @parent
    assert_template('show')
  end

  def test_update_with_replace
    @school.parents.expects(:find).returns(@new_parent = Parent.new(:first_name => 'test', :last_name => 'parent'))
    put :update, :student_id => :child, :replace => '1', :id => @parent
    assert @student.parents.include?(@new_parent)
  end
end
