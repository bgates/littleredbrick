require 'test_helper'

class People::StudentsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns(true)
    @school.stubs(:students).returns(@students = mock())
  end

  def test_index
    prep_index
    @school.stubs(:terms).returns([Term.new(:low_period => 1, :high_period => 6)])
    get :index
    assert_response :success
  end

  def test_next_term_index
    prep_index
    @school.stubs(:terms).returns([Term.new, Term.new(:low_period => 1, :high_period => 6)])
    get :index, :term => 'future'
    assert_response :success
  end

  def test_show
    @students.expects('find').returns(@student = Student.new(:first_name => 'child'))
    @rbes = Array.new(2){RollbookEntry.new}
    @student.stub_path('rollbook_entries.where.includes.sort_by').returns(@rbes)
    @sections = Array.new(2){|n| Section.new(:time => n + 1, :track_id => 1)}
    @sections.each do |s|
      s.stubs(:teacher).returns(teacher = Teacher.new(:last_name => 'teacher'))
      s.stubs(:name).returns('class')
    end
    @rbes.each_with_index do |rbe, i|
      rbe.stubs(:section).returns(@sections[i])
      rbe.stubs(:milestones).returns([Milestone.new(:reported_grade_id => 2)])
    end
    prep_mp
    MarkingPeriod.expects(:find_by_track_id_and_position).with(1, 1).returns(mock(:reported_grade_id => 2))
    get :show, :id => 1
    assert_response :success
  end

  def test_show_empty
    @students.expects('find').returns(@student = Student.new(:first_name => 'child'))
   @controller.expects(:find_from_track).returns([MarkingPeriod.new])
    Track.expects(:current_marking_period).returns(mock(:position => 1))
    get :show, :id => 1
    assert_response :success
  end

  def test_edit
    prep_edit
    @students.expects(:find).with(1).returns(@student = Student.new(:first_name => 'name', :last_name => 'test'))
    @student.stubs(:id).returns(1)
    get :edit, :id => 1
    assert_response :success
  end

  def test_new
    prep_edit
    get :new
    assert_response :success
  end

  def test_update
    prep_update
    put :update, :id => 1
    assert_redirected_to student_path(@student)
  end

  def test_update_with_reset
    prep_update
    put :update, :id => 1, :student => {:reauthorize => true}
    assert_redirected_to student_path(@student)
  end

  def test_update_fail
    prep_update(false)
    prep_school
    put :update, :id => 1
    assert_template('edit')
  end

  def test_destroy
    prep_destroy
    delete :destroy, :id => 1
    assert_redirected_to students_path
  end

  def test_destroy_xhr
    prep_destroy
    xhr :delete, :destroy, :id => 1
    assert_response :success
  end

  def test_destroy_fail
    prep_destroy(false)
    delete :destroy, :id => 1
    assert_redirected_to student_path(@student)
  end

  def test_create
    prep_create
    @student.stubs(:authorization).returns(stub(:login => 'test'))
    post :create, :student => {:first_name => 'test', :last_name => 'name', :authorization => {:password => 'secret'}}
    assert_redirected_to students_path
  end

  def test_create_fail
    prep_create(false)
    prep_school
    post :create
    assert_template('new')
  end

  def test_sections
    @students.expects(:find).with(1).returns(@student = Student.new(:first_name => 'test', :last_name => 'name'))
    @student.stubs(:id).returns(1)
    Section.stub_path('includes.where.first').returns(@section = Section.new)
    prep_mp
    Section.stub_path('where.includes').returns([@section])
    @section.stubs(:teacher).returns(stub(:display_name => 'teacher'))
    get :sections, :id => 1
    assert_response :success
  end

  def test_marks
    @students.expects(:find).with(1).returns(@student = Student.new(:first_name => 'test', :last_name => 'name'))
    @student.stub_path('rollbook_entries.includes').returns([@rbe = RollbookEntry.new])
    teacher = stub(:display_name => 'teacher', :to_param => 'teacher')
    @rbe.stubs(:teacher).returns(teacher)
    @rbe.stubs(:name).returns('subject name')
    @rbe.expects(:time).returns('section time')
    @rbe.stubs(:section).returns stub(:to_param => 'section', :teacher => teacher)
    get :marks, :id => 1
    assert_response :success
  end
  protected
  def prep_index
    @students.expects(:includes).with({:rollbook_entries => {:section => :subject}}).returns([Student.new])
  end

  def prep_edit
    School.expects(:find).returns(@school)
    prep_school
  end

  def prep_update(response = true)
    @students.expects(:find).with(1).returns(@student = Student.new(:first_name => 'name', :last_name => 'test'))
    @student.expects(:update_attributes).returns(response)
  end

  def prep_destroy(response = true)
    @students.expects(:find).with(1).returns(@student = Student.new(:first_name => 'name', :last_name => 'test'))
    @student.expects(:destroy).returns(response)
  end

  def prep_create(response = true)
    @students.expects(:create).returns(@student = Student.new)
    @student.expects(:valid?).returns(response)
  end

  def prep_school
    @school.low_grade, @school.high_grade = 9, 12
  end

end
