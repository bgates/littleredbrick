require 'test_helper'

class Gradebook::IndividualControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    Section.stubs(:find).returns(@section = Section.new)
    @section.stubs(:teacher).returns(@user)
    @section.stubs(:to_param).returns 'id'
    @user.stubs(:display_name).returns 'mr teacher'
    @section.stubs(:belongs_to?).returns true
  end

  def test_fail_login
    @controller.stubs(:authorized?).returns(false)
    get :show, {:section_id => @section, :id => :id}, {:school => :exists, :user => :exists}
    assert_redirected_to login_path
  end

  def test_show
    prep_mp
    prep_rbe
    @user.stubs(:teaches?).returns true
    @milestone = Milestone.new
    @milestone.stubs(:class_rank).returns(1)
    @rbe.expects(:milestones).returns(stub(:detect => @milestone))
    get :show, :section_id => @section, :id => 'student'
    assert_response :success
    assert_select '#content', /contributed no comments/
  end

  def test_assignments
    prep_rbe
    prep_index
    get :assignments, :section_id => @section, :id => 'student'
    assert_response :success
  end

  def test_marks
    prep_rbe
    @rbe.expects(:sort_milestones).returns([@milestone = Milestone.new])
    @milestone.stubs(:reported_grade).returns(stub(:description => 'mp'))
    get :marks, :section_id => @section, :id => 'student'
    assert_response :success
  end

  protected

    def prep_index
      @section.expects(:current_marking_period).returns(stub(:reported_grade_id => 1))
      @section.expects(:marking_periods).returns([stub(:position => 1)])
    end

    def prep_rbe
      @section.stub_path('rollbook_entries.with_all_info').returns(@rbe = RollbookEntry.new)
      @rbe.stubs(:student).returns(@student = Student.new(:first_name => 'test', :last_name => 'student'))
    end
end

