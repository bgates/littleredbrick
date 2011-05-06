require 'test_helper'

class ReportedGradeTest < ActiveSupport::TestCase

  def test_grade_for_section
    Section.stubs(:find).with(1).returns(@section = Section.new)
    @section.expects(:term).returns(Term.new)
    @section.expects(:add_milestones).returns(true)
    ReportedGrade.create(:reportable_type => 'Section', :reportable_id => 1, :description => 'exam for section', :predecessor_id => 0)
  end

  def test_grade_for_term
    Term.stubs(:find).with(1).returns(@term = Term.new)
    @term.expects(:sections).returns([@section = Section.new])
    @section.expects(:add_milestones).returns(true)
    ReportedGrade.create(:reportable_type => 'Term', :reportable_id => 1, :description => 'exam for term', :predecessor_id => 0)
  end

  def test_marking_period_creation
    Term.expects(:find).with(1).returns(@term = Term.new)
    mp = 3
    @term.expects(:marking_periods).returns(stub(:size => mp))
    @grade = ReportedGrade.new(:reportable_type => 'Term', :reportable_id => 1, :description => 'Marking Period', :predecessor_id => 1, :allowed => true)
    @grade.send(:enumerate)
    assert_equal 'Marking Period 4', @grade.description
  end

  def test_set_predecessor_0_for_section
    Section.expects(:find).with(1).returns(mock(:term => Term.new))
    stub_callbacks
    @grade = ReportedGrade.create(:description => 'midterm', :reportable_id => 1, :reportable_type => 'Section')
    assert_equal 0, @grade.predecessor_id
  end

  def test_set_predecessor_for_section
    @rgs = [stub(:id => 1, :predecessor_id => 0), stub(:id => 10, :predecessor_id => 1), stub(:id => 20, :predecessor_id => 10)]
    Section.expects(:find).with(1).returns(mock(:term => mock(:reported_grades => (@rgs))))
    stub_callbacks             
    @grade = ReportedGrade.create(:description => 'midterm', :reportable_id => 1, :reportable_type => 'Section')                                 
    assert_equal 20, @grade.predecessor_id
  end

  def test_destroy
    @grade = ReportedGrade.new(:description => 'Marking Period 2', :reportable_id => 1, :reportable_type => 'Term')
    Term.expects(:find).with(1).returns(@term = Term.new)
    reported_grades = @term.reported_grades
    reported_grades.expects(:where).returns(stub(:order => stub(:first => mock(:id => 1))))
    @grade.expects(:assignments).returns([@assignment = Assignment.new])
    @assignment.expects(:update_attributes).with(:reported_grade_id =>  1)
    assert @grade.send(:change_assignment_mp)
  end

  def test_destroy_non_mp
    @grade = ReportedGrade.new(:description => 'not an mp')
    assert @grade.send(:change_assignment_mp)
  end

  def test_destroy_first_mp
    @grade = ReportedGrade.new(:description => 'Marking Period 2', :reportable_id => 1, :reportable_type => 'Term')
    Term.expects(:find).with(1).returns(@term = Term.new)
    assert @grade.send(:change_assignment_mp)
  end

  def test_set_positions_new
    Term.stubs(:find).with(1).returns(@term = Term.new)
    @g = ReportedGrade.create(:reportable_id => 1, :reportable_type => 'Term', :description => 'only')
    assert_equal 0, @g.predecessor_id
  end

  def test_set_positions_middle
    prep_insert
    @g.send(:set_predecessor)
    assert_equal 2, @g.predecessor_id
  end

  def test_adjust_position_after_insert
    prep_insert
    @g.stubs(:id).returns(4)
    @moved.expects(:update_attribute).with(:predecessor_id, 4).returns(@moved)
    @g.send(:set_predecessor)
    assert @g.send(:insert_predecessor)
  end

  def test_reset_position_after_destroy
    prep_insert
    ReportedGrade.expects(:find_all_by_predecessor_id).with(2).returns([@moved])
    @moved.expects(:update_attribute).with(:predecessor_id, 1)
    assert @stationary.send(:remove_predecessor)
  end

  def test_only_add_mp_outside_of_form
    @grade = ReportedGrade.new(:reportable_type => 'Term', :reportable_id => 1, :description => 'marking period')
    assert !@grade.valid?
    assert_equal "must not be 'marking period'", @grade.errors[:description][0]
  end

  def test_uniqueness_of_section_grade
    Section.expects(:find).returns(mock(:term => mock(:id => 10)))
    ReportedGrade.stubs(:where).with(['description = ? AND reportable_id = ? AND reportable_type = ?', 'duplicate', 10, 'Section']).returns(stub(:first => mock()))
    @grade = ReportedGrade.new(:reportable_type => 'Section', :reportable_id => 10, :description => 'duplicate')
    @grade.expects(:existing_term_grade).returns(nil)
    assert @grade.invalid?
  end

  def test_uniqueness_of_section_grade_on_update
    Section.expects(:find).returns(mock(:term => mock(:id => 10)))
    @grade = ReportedGrade.new(:reportable_type => 'Section', :reportable_id => 10, :description => 'unique')
    @grade.stubs(:new_record?).returns(false)
    @grade.stubs(:id).returns(404)
    assert @grade.valid?
  end

  def test_average
    @rg = ReportedGrade.new
    prep_gather
    @rg.expects(:gather).with(:predecessors, :section).returns(@gather_result)
    @final_1, @final_2 = Milestone.new(:rollbook_entry_id => 1), Milestone.new(:rollbook_entry_id => 2)
    @rg.expects(:gather).with(nil, :section).returns([@final_1, @final_2].group_by(&:rollbook_entry_id))
    @final_1.expects(:average_of).with(@gather_result[1])
    @final_2.expects(:average_of).with(@gather_result[2])
    assert @rg.average_of(:predecessors, :section)
  end

  def test_gather
    @rg = ReportedGrade.new
    @section = Section.new
    prep_gather
    @section.expects(:milestones).returns(stub(:where => @milestones))
    assert_equal @gather_result, @rg.gather(:marks, @section)
    assert_equal @gather_result[2], [@same_1, @same_2]
  end

  def test_move_assignments
    @rg = ReportedGrade.new(:description => 'Marking Period 4')
    Term.expects(:find).returns(@term = Term.new)
    @term.expects(:reported_grades).returns(stub(:where => stub(:order => stub(:first => @previous = ReportedGrade.new))))
    @rg.expects(:assignments).returns([@assignment = Assignment.new])
    @previous.stubs(:id).returns('id')
    @assignment.expects(:update_attributes).with({:reported_grade_id => 'id'})
    assert @rg.destroy
  end

  def test_weight
    prep_weight_or_combine
    @current.each{|m| m.expects(:weight_by)}
    assert @rpg.weight_by({1 => 40, 2 => 40, 3 => 20}, @section)
  end

  def test_combine
    prep_weight_or_combine
    @current.each{|m| m.expects(:combine)}
    assert @rpg.combine([1,2,3], @section)
  end

  def test_order
    @marks = Array.new(5) do |n|
      g = ReportedGrade.new(:predecessor_id => switcheroo(n + 1),
                            :reportable_type => 'Term')
      g.stubs(:id).returns(n + 1)
      g
    end
    @ordered_list = ReportedGrade.sort(@marks)
    assert_equal @ordered_list.map(&:id), [1,2,4,3,5]
  end

  def test_order_with_section_grade
    @marks = Array.new(4) do |n|
      g = ReportedGrade.new(:predecessor_id => n, :reportable_type => 'Term')
      g.stubs(:id).returns(n + 1)
      g
    end
    section_grade = ReportedGrade.new(:predecessor_id => 2, :reportable_type => 'Section')
    section_grade.stubs(:id).returns(5)
    @marks << section_grade
    @ordered_list = ReportedGrade.sort(@marks)
    assert_equal [1, 2, 5, 3, 4], @ordered_list.map(&:id)
  end

  def test_reset
    @rpg = ReportedGrade.new
    @rpg.stubs(:id ).returns('id')   
    Milestone.any_instance.expects(:reset!).times(2)
    @rpg.expects(:gather).with('id', :section).returns({1 => Milestone.new, 2 => Milestone.new})
    assert @rpg.reset!(:section)
  end
  protected
    def prep_insert
      @term = Term.new; Term.stubs(:find).returns(@term)
      @grades = @term.reported_grades
      @moved = ReportedGrade.new(:predecessor_id => 2); @moved.stubs(:id).returns(3)
      @stationary = ReportedGrade.new(:predecessor_id => 1); @stationary.stubs(:id).returns(2)
      @grades << @stationary; @grades << @moved
      @g = @term.reported_grades.build(:description => 'midterm', :predecessor_id => 2)
    end

    def prep_gather
      @changed_1, @changed_2 = Array.new(2){ Milestone.new(:rollbook_entry_id => 1)}
      @same_1, @same_2 = Array.new(2){ Milestone.new(:rollbook_entry_id => 2)}
      @milestones = [@changed_1, @changed_2, @same_1, @same_2]
      @gather_result = @milestones.group_by(&:rollbook_entry_id)
    end

    def prep_weight_or_combine
      @section = Section.new
      @milestones = @section.milestones
      @predecessors = Array.new(6) do |n| 
        obj = RollbookEntry.new
        obj.stubs(:rollbook_entry_id).returns(10 * (1 + (n + 1) / 3))
        obj
      end
      @current = Array.new(2) do |n| 
        obj = RollbookEntry.new
        obj.stubs(:rollbook_entry_id).returns(10 * (1 + (n + 1) / 2))
        obj
      end
      @milestones.expects(:where).with(['reported_grade_id IN (?)', [1,2,3]]).returns(@predecessors)
      @milestones.expects(:where).with(['reported_grade_id IN (?)', 4]).returns(@current)
      @rpg = ReportedGrade.new
      @rpg.expects(:id).returns(4)
    end

    def stub_callbacks
      [:add_milestones, :insert_predecessor, :check_name].each do |method|
        ReportedGrade.any_instance.expects(method).returns(true)
      end
    end

    def switcheroo(n)
      case n
      when 1, 2
        n - 1
      when 3
        4
      else n - 2
      end
    end
end

