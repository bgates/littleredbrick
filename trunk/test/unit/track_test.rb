require 'test_helper'

class TrackTest < Test::Unit::TestCase

  def setup
    @track = Track.new
  end

  def test_create
    prep_term
    @track.save
    assert_equal Date.today, @track.start
    assert_equal 3, @track.marking_periods(true).count
  end

  def test_create_with_mp
    prep_term
    @track.new_marking_periods = [{:start => Date.today + 5, :finish => Date.today + 90},
                                  {:start => Date.today + 100, :finish => Date.today + 180},
                                  {:start => Date.today + 200, :finish => Date.today + 270}]
    @track.save
    assert_equal Date.today + 5, @track.start
    assert_equal 3, @track.marking_periods(true).count
  end

  def test_fail_create_with_disordered_mp
    prep_term
    @track.new_marking_periods = [{:start => Date.today + 5, :finish => Date.today + 90},
                                  {:start => Date.today + 10, :finish => Date.today + 180},
                                  {:start => Date.today + 200, :finish => Date.today + 270}]
    @track.save
    assert ! @track.valid?
    assert @track.marking_periods.find(:all).empty?
  end

  def test_errors_tidied
    prep_term
    @track.new_marking_periods = [{:start => Date.today + 5, :finish => Date.today + 90},
                                  {:start => Date.today + 100, :finish => Date.today + 95},
                                  {:start => Date.today + 200, :finish => Date.today + 270}]
    assert ! @track.valid?
    assert_equal 'must be after start date', @track.errors[:marking_periods_finish][0]
  end

  def test_start
    @track.expects(:marking_periods).returns([stub(:start => Date.today), stub(:start => Date.today + 100)])
    assert_equal @track.start, Date.today
  end

  def test_finish
    @track.expects(:marking_periods).returns([stub(:finish => Date.today), stub(:finish => Date.today + 100)])
    assert_equal @track.finish, Date.today + 100
  end

  def test_current
    @track.expects(:marking_periods).returns([stub(:start => Date.today - 10, :id => :first), stub(:start => Date.today - 5, :id => :middle), stub(:start => Date.today + 10)])
    assert_equal :middle, @track.current_marking_period.id
  end

  def test_current_defaults_to_first
    @track.expects(:marking_periods).times(2).returns([stub(:start => Date.today + 10, :id => :first), stub(:start => Date.today + 15, :id => :middle), stub(:start => Date.today + 20)])
    assert_equal :first, @track.current_marking_period.id
  end

  def test_update
    @track.expects(:add_marking_periods).returns true
    @track.save(:validate => false)
    @track.archive = Date.today
    @track.expects(:finish).at_least_once.returns(Date.today + 1)
    @track.expects(:term_id).at_least_once.returns(1)
    assert !@track.valid?
    @track.archive = @track.finish + 1
    assert @track.valid?
  end

  def test_no_mp_overlap
    @track.marking_periods.build(:start => Date.today, :finish => Date.today + 10)
    @track.marking_periods.build(:start => Date.today + 5, :finish => Date.today + 20)
    @track.stubs(:initialize_marking_periods).returns(true)
    assert !@track.valid?
    assert !@track.errors[:base].empty?
  end

  def test_update_mps
    @mps = Array.new(2){|n| MarkingPeriod.new}
    @mps.each_with_index{|mp, i| mp.stubs(:id).returns(i)}
    @track.stubs(:marking_periods).returns(@mps)
    @track.existing_marking_periods = {'0' => {:start => Date.today}, '1' => {:start => Date.today}}
    assert_equal Date.today, @track.marking_periods.first.start
    assert @track.marking_periods.last.skip_sequence_validation
  end

  def test_occupied
    @track.expects(:sections).returns(mock(:count => 1))
    assert @track.occupied?
  end
  protected
  def prep_term
    @term = mock()
    @rpg, @rpg2, @rpg3 = ReportedGrade.new, ReportedGrade.new, ReportedGrade.new
    @rpg.stubs(:id).returns(501)
    @rpg2.stubs(:id).returns(502)
    @rpg3.stubs(:id).returns(503)
    @term.expects(:marking_periods).at_least_once.returns([@rpg, @rpg2, @rpg3])
    @track.term_id = 'present'
    @track.stubs(:term).returns(@term)
  end
end

