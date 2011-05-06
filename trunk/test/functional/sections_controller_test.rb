require 'test_helper'

class SectionsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    @request.session[:return_to] = 'for link on edit_grade_scale'
    Section.stubs(:find).returns(@section = Section.new)
    @section.stubs(:includes).returns @section
    @section.stubs(:teacher).returns(@teacher)
    @teachers = stub(:find => @teacher, :collect => [@teacher])
    @school.stubs(:teachers).returns(@teachers)
    @section.stubs(:subject).returns(@subject = Subject.new(:name => 'algebra'))
  end

  def test_index
    @teacher.stubs(:teaches?).returns true
    @teacher.stub_path('sections.includes').returns [@section]
    @teacher.expects(:may_access_forum_for?).returns(true)
    find_section_data
    Subject.any_instance.stubs(:department_id).returns 'dept'
    @school.expects(:terms).returns(stub(:count => 1))
    get :index
    assert_template('index')
  end

  def test_show
    Section.stubs('find').returns @section
    @section.expects(:grade_distribution).at_least_once.returns(Hash.new{|k,v| Milestone.new})
    @subject.expects(:department).returns(@dept = Department.new)
    find_section_data
    get :show, :id => 'test'
    assert_not_nil assigns(:section)
    assert_template('show')
  end

  def test_edit
    @subject.stubs(:department).returns(stub(:subjects => [@subject]))
    @teachers.stubs(:length).returns 1
    track = Track.new
    track.expects(:term).at_least_once.returns(Term.new(:low_period => 1, :high_period => 6))
    @section.expects(:track).at_least_once.returns(track)
    get :edit, :id => 'test'
    assert_not_nil assigns(:section)
    assert_template('edit')
  end
                         
  def test_update
    Section.stubs('find').returns @section
    put :update, :id => 'test', :section => {:teacher_id => 404}
    assert_redirected_to section_url(@section)
  end

  def test_edit_grade_scale
    get :edit, :id => 'test', :grade_scale => ''
    assert_template('edit_grade_scale')
  end

  def test_update_grade_scale
    Section.stubs('find').returns @section
    @section.expects(:update_attributes).returns(true)
    put :update, :id => 'test', :section => {:grade_scale => []}
    assert_redirected_to section_url(@section)
  end

  def test_fail_update_grade_scale
    @section.expects(:update_attributes).returns(true)
    @section.errors[:grade_scale] = 'error'
    put :update, :id => 'test', :section => {:grade_scale => []}
    assert_template('edit_grade_scale')
  end

  def test_update_all
    Section.stubs('find').returns @section
    @section.expects(:update_attributes).returns(true)
    put :update, :id => 'test', :section => {:grade_scale => []}, :all_sections => true
    assert_redirected_to section_url(@section)
  end

  def test_destroy
    @section.expects(:destroy).returns(true)
    delete :destroy, :id => 'test'
    assert_redirected_to sections_path
  end

  protected

    def find_section_data
      MarkingPeriod.expects(:find_all_by_track_id).returns([@mp = MarkingPeriod.new(:position => 1)])
      Track.expects(:current_marking_period).returns(@mp)
    end
end
