require 'test_helper'

class TeachingLoadControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    @controller.stubs(:authorized?).returns(true)
    @school.stub_path('teachers.find').returns(@teacher)
    @teacher.stubs(:id).returns 'id'
    terms = [ @term = Term.new(:low_period => 1, :high_period => 5) ]
    @school.stubs(:terms).returns terms
  end

  def test_fail_login
    @controller.stubs(:authorized?).returns(false)
    get :edit, :teacher_id => @teacher
    assert_redirected_to login_path
  end

  def test_new_redirects
    @controller.expects(:find_sections).returns [Section.new]
    @teacher.expects(:to_param).returns('teacher with sections')
    get :new, :teacher_id => 'teacher with sections'
    assert_redirected_to edit_teaching_load_path('teacher with sections')
  end

  def test_new
    @controller.stubs(:find_sections).returns([])
    get :new, :teacher_id => @teacher
    assert_template('new')
  end

  def test_create_self
    @teacher.expects(:admin?).times(2).returns(false)
    @teacher.expects(:update_attributes)
    post :create, :teacher_id => @teacher, :teacher => { :sections_attributes => [{:subject_id => :subj}, {:subject_id => :subj_2}]}
    assert flash[:notice] =~ /Your class list/
    assert_redirected_to sections_path
  end

  def test_create_as_admin
    @controller.stubs(:current_user).returns stub(:admin? => true)
    @teacher.expects(:update_attributes)
    post :create, :teacher_id => @teacher, :teacher => { :sections_attributes => [{:subject_id => :subj}, {:subject_id => :subj_2}]}
    assert flash[:notice] =~ /The class list for/
    assert_redirected_to teachers_path
  end

  def test_create_for_future_term
    @teacher.expects(:update_attributes)
    post :create, :teacher_id => @teacher, :teacher => { :sections_attributes => [{:subject_id => :subj}, {:subject_id => :subj_2}]}, :term => 'future'
    assert_redirected_to term_staging_path(@term, :teacher_id => @teacher)
  end
    
  def test_edit
    @teacher.sections.stub_path('anytime.where').returns(@sections = [Section.new, Section.new])
    @sections.each_with_index{|s, i| s.stubs(:id).returns(i)}
    @teacher.expects(:departments).returns([@dept = Department.new])
    @teacher.expects(:department_subjects).returns []
    2.times{|n| @teacher.sections.build }
    @dept.stubs(:id).returns(1)
    @term.expects(:tracks).returns([@track = Track.new])
    get :edit, :teacher_id => 'teacher'
    assert_equal(assigns(:tracks), [@track])
    assert_select '#section_form' do
      @sections.each_with_index do |section, i|
        assert_select "input[name*=?][type=hidden]","teacher[sections_attributes][#{i}][track_id]"
      end
    end
  end

  def test_edit_empty
    @teacher.sections.stub_path('anytime.where').returns(@teacher.sections)
    get :edit, :teacher_id => @teacher.id
    assert_template('edit')
    assert_select 'select[name*=?]',"teacher[sections_attributes][0][subject_id]" do
      assert_select 'option', 0
    end
  end

  def test_edit_xhr
    Subject.expects(:find_all_by_department_id).with([2,3]).returns [@subject = Subject.new]
    @teacher.stubs(:to_param).returns 'id'
    xhr :get, :edit, {:department => {2 => 2, 3 => 3}, :length => 2, :teacher_id => @teacher}
    assert_match @response.body, /cloneNode/
  end

  def test_remove_section
    Section.expects(:find_by_id_and_teacher_id).with('section_id', 'id').returns section = Section.new
    section.expects(:destroy).returns true
    xhr :post, :destroy, {:section_id => 'section_id', :teacher_id => @teacher }
    assert_select_rjs :remove, "section_section_id"
  end

  def test_department_selection
    @school.stub_path('departments').returns [@dept = Department.new]
    @dept.stubs(:id).returns 100
    @teacher.stubs(:department_subjects).returns [@subject = Subject.new]
    @subject.stubs(:id).returns 'subject id'
    @subject.stubs(:name).returns 'name'
    @section = @teacher.sections.build
    @teacher.sections.stub_path('anytime.where').returns [@section]
    get :edit, {:department => {'id' => '100'}, :teacher_id => @teacher}
    assert_template('edit')
    assert_select 'option[value=?]','subject id', :text => 'name'
  end

  def test_department_selection_xhr
    @school.stub_path('departments').returns [@dept = Department.new]
    Section.stub_path('where.includes').returns [Section.new]
    xhr :get, :edit, {:department => {28 => 28}, :teacher_id => @teacher.id}
    assert_equal assigns(:department_subjects), []
  end

  def test_update
    put :update, :teacher_id => @teacher
    assert_redirected_to sections_path
  end
  
  def test_update_initial
    @teacher.expects(:update_attributes)
    put :update, { :teacher_id => @teacher,
                   :teacher => { :sections_attributes => [{ :new => :section }]}
                  },
                { :initial => true, :school => :exists, :user => :exists}
    assert_redirected_to teachers_url
  end
end
