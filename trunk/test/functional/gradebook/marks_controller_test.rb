require 'test_helper'

class Gradebook::MarksControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    term_setup
    Section.stub_path('includes.find').returns @section = Section.new
    @section.stubs(:term).returns @term
    @section.stubs(:teacher).returns @user
    @section.stubs(:to_param).returns 'id'
    @user.stubs(:display_name).returns 'mr teacher'
    @mark = ReportedGrade.new(:description => 'the grade')
  end
  # gotta show the reported grades for a section, and milestones for all students
  #gotta add a section reported grade before everything, in the middle, and at the end

  def test_login_fail
    @section.stubs(:teacher).returns Teacher.new
    get :index, {:section_id => @section}, :school => :exists, :user => :user
    assert_redirected_to login_path
  end

  def test_create
    prep_create true
    post :create, :section_id => 'id', :mark => {:description => 'test', :predecessor_id => 'predecessor'}
    assert_redirected_to section_marks_path(@section)
  end

  def test_create_fail
    prep_create false
    @marks = [stub(:description => 'first', :id => 1), stub(:description => 'final', :id => 2)]
    @mark.errors.add(:description, "must not be blank")
    @section.stubs(:marks).returns @marks
    post :create, :section_id => 'id', :mark => {:description => 'test', :predecessor_id => 'predecessor'}
    assert_template('new')
    assert_select 'div#errorExplanation'
  end

  def test_destroy
    @section.stub_path('reported_grades.find').returns @mark = stub
    @mark.expects(:destroy)
    @mark.stubs(:description).returns 'the grade'
    delete :destroy, :section_id => 'id', :id => 'mark'
    assert_redirected_to section_marks_path(@section)
  end
  
  def test_edit_no_predecessors
    prep_milestones
    @section.stubs(:marks).returns [@mark, ReportedGrade.new, ReportedGrade.new]
    get 'edit', :section_id => @section, :id => @mark
    assert_equal assigns(:predecessor_rg), []
  end

  def test_edit_one_predecessor
    prep_edit
    @mark.errors.add(:base, 'something broke')
    get :edit, :section_id => @section, :id => @mark
    assert_template 'edit'
    assert_equal assigns(:predecessors), @pred_stones.group_by(&:rollbook_entry_id)
  end

  def test_edit_several_predecessors
    prep_milestones
    prep_multiple_milestones
    @next_stones = Array.new(2){|i| Milestone.new(:rollbook_entry_id => i)}
    @next_pred = ReportedGrade.new(:description => 'predecessor') 
    @next_pred.stubs(:milestones).returns @next_stones
    @next_pred.stubs(:to_param).returns 'id'
    @section.stubs(:marks).returns [@predecessor, @next_pred, @mark]
    get 'edit', :section_id => @section, :id => @mark
    assert_equal assigns(:predecessors), (@pred_stones + @next_stones).group_by(&:rollbook_entry_id)
  end

  def test_index
    get :index, :section_id => @section
    assert_template('index')
  end

  def test_index_empty
    get 'index', :section_id => @section
    assert_template('index')
  end

  def test_new
    get :new, :section_id => @section
    assert_template 'new'
  end

  def test_show
    find_mark
    get :show, :section_id => @section, :id => @mark
    assert_template 'show'
  end

  def test_show_mp
    find_mark
    @mark.stubs(:description).returns 'Marking Period'
    @mark.stubs(:id).returns 1
    @mark.stub_path('marking_periods.find_by_track_id').returns MarkingPeriod.new
    get :show, :section_id => @section, :id => @mark
    assert_equal(1, assigns(:section).reported_grade_id)
  end

  def test_update_mark
    find_mark
    @mark.expects(:update_attributes).returns true
    put :update, :section_id => @section, :id => @mark, :commit => "Update Mark"
    assert_redirected_to section_marks_path @section
  end

  def test_update_milestones
    find_mark
    Milestone.expects(:update).with(['keys'], [:values])
    put :update, :section_id => @section, :id => @mark, :commit => "Save", :marx => {:keys => :values}
    assert_redirected_to section_marks_path(@section)
  end
  
  def test_update_avg
    find_mark
    @mark.expects(:average_of).with([1,3], @section).returns(stub(:all? => true))
    put :update, :section_id => @section, :id => @mark, :commit => 'Average', :avg => {1 => 1, 3 => 3}
    assert_redirected_to section_marks_path(@section)
  end

  def test_update_fail_no_marks
    find_mark
    @controller.expects(:set_marks_by_commit).returns nil
    put :update, :section_id => @section, :id => @mark
    assert_redirected_to section_marks_path @section
  end
   
  def test_update_fail
    prep_edit
    @mark.expects(:update_attributes).returns false
    @mark.errors.add(:base, 'something wrong')
    put :update, :section_id => @section, :id => @mark, :commit => 'Update Mark'
    assert_template('edit')
    assert_select 'div#errorExplanation'
  end

  def test_update_pts
    find_mark
    @mark.expects(:combine).with([1, 2, 3], @section).returns(stub(:all? => true))
    put :update, :section_id => @section, :id => @mark, :commit => 'Combine', :pts => {1 => 1, 2 => 2, 3 => 3}
    assert_redirected_to section_marks_path(@section)
  end

  def test_update_weighted_avg
    find_mark
    weight_hash = {0 => '30', 1 => '30', 2 => '40'}
    @mark.expects(:weight_by).with(weight_hash, @section).returns(stub(:all? => true))
    put :update, :section_id => @section, :id => @mark, :commit => "Weight", :wt => weight_hash
    assert_redirected_to section_marks_path(@section)
  end

  def test_update_weight_fail
    prep_edit
    put :update, :section_id => @section, :id => @mark, :commit => 'Weight', :wt => {0 => 99}
    assert_template 'calculate'
  end

protected

  def find_mark
    ReportedGrade.stub_path('where.find').returns @mark
    @mark.stubs(:to_param).returns 'id'
  end

  def prep_create(valid)
    @mark.expects(:valid?).returns valid
    @section.stub_path('reported_grades.create').returns @mark 
  end

  def prep_edit
    prep_milestones
    prep_multiple_milestones
    @section.stubs(:marks).returns [@predecessor, @mark, ReportedGrade.new]
  end

  def prep_milestones
    find_mark
    @milestones = Array.new(2){|i| Milestone.new(:rollbook_entry_id => i)}
    @mark.stubs(:milestones).returns @milestones 
  end

  def prep_multiple_milestones
    @pred_stones = Array.new(2){|i| Milestone.new(:rollbook_entry_id => i)}
    @student = Student.new(:first_name => 'a', :last_name => 'student')
    @students = Array.new(2){|i| stub(:id => i, :student => @student)}
    @section.stub_path('rollbook_entries.includes.order').returns @students
    @predecessor = ReportedGrade.new(:description => 'predecessor') 
    @predecessor.stubs(:milestones).returns @pred_stones
    @predecessor.stubs(:to_param).returns 'id'
  end
end
