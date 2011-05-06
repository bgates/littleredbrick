require 'test_helper'

class Catalog::CatalogsControllerTest < ActionController::TestCase

  def setup
    generic_setup Staffer
    @request.session[:initial] = true
  end

  def test_get_index
    get :new
    assert_equal assigns(:school).departments[0].subjects.collect(&:name), Department.generic_choices[0].subjects.collect(&:name)
  end

  def test_setup_catalog
    @school.expects(:update_attributes)
    post :create, :school => {:departments_attributes => {1 => {:name => 'Mathematics', :subjects_attributes => {0 => {:name => 'Algebra'}, 1 => {:name => 'Geometry'}, 2 => {:name => 'Calculus'}, 3 => {:name => ''} }}, 2 => {:name => 'English', :subjects_attributes => {0 => {:name => 'Poetry'}, 1 => {:name => 'Prose'}, 2 => {:name => ''} }}}}
    assert_redirected_to home_url
  end

  def test_revise_catalog
    @school.expects(:update_attributes)
    put :update, :school => { :departments_attributes => {}}
    assert_redirected_to '/'
  end

  def test_revise_failed
    department = Department.create(:name => 'Math', :subjects_attributes => [{:name => 'Algebra'}])
    department.stubs(:valid?).returns false
    @school.expects(:update_attributes)
    @school.stubs(:departments).returns [department]
    put :update, :school => { :departments_attributes => {0 => {:name => '', :id =>  department.id}}}
    assert_template('edit')
  end

end
