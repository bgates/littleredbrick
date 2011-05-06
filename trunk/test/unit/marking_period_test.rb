require 'test_helper'

class MarkingPeriodTest < ActiveSupport::TestCase
  def setup
    @track = Track.new
  end

  def test_invalid_order
    mp = MarkingPeriod.new(:track_id => 1, :start => Date.today, :finish => Date.today - 2)
    assert ! mp.valid?
    assert_equal mp.errors[:finish], ["must be after start date"]
  end

  def test_valid_if_no_overlap
    prep_overlap
    assert @first_mp.valid?
    assert @last_mp.valid?
    @first_mp.finish = @last_mp.start - 2
    assert @first_mp.valid?
  end

  def test_invalid_if_finish_overlaps_subsequent_start
    prep_overlap
    @track.stubs(:initialize_marking_periods).returns(true)
    @first_mp.save
    @first_mp.finish =  @last_mp.start + 7; @first_mp.valid?
    assert_equal ['must be before start date of subsequent marking period'], @first_mp.errors[:finish]
  end

  def test_invalid_if_start_overlaps_previous_finish
    prep_overlap
    @track.stubs(:initialize_marking_periods).returns(true)
    @last_mp.save
    @last_mp.start = @first_mp.finish - 7; @last_mp.valid?
    assert_equal ['must be after end date of previous marking period'], @last_mp.errors[:start]
  end

  def test_invalid_date
    mp = MarkingPeriod.new(:track_id => 1, :start => 'invalid date', :finish => Date.today - 2)
    assert !mp.valid?
    assert_equal mp.errors[:start], ["must be in date format (yyyy-mm-dd)"]
  end

  def test_invalid_archive_overlap
    prep_overlap
    @track.expects(:archive).at_least_once.returns(Date.today + 90)
    @last_mp.finish = Date.today + 91
    assert ! @last_mp.valid?
    assert_equal @last_mp.errors[:finish], ['must be before the track is archived']
  end

  def test_on_calendar
    prep_mps
    MarkingPeriod.expects(:where).returns([@first_mp, @last_mp])
    @start, @finish = @first_mp.finish - 5, @last_mp.start + 5
    @cal = MarkingPeriod.on_calendar(@track, @start, @finish)
    assert_equal 2, @cal.length
    assert @cal[0].name = 'Begin Marking Period 2'
  end

  def test_name
    @mp = MarkingPeriod.new
    @mp.expects(:reported_grade).returns(mock(:description => 'marking period n'))
    assert_equal 'marking period n', @mp.name
  end
private

  def prep_overlap
    Track.stubs(:find).returns(@track)
    prep_mps
    @first_mp.stubs(:id).returns(1)
    @last_mp.stubs(:id).returns(2)
    @track.stubs(:marking_periods).returns([@first_mp, @last_mp])
  end

  def prep_mps
    @first_mp = MarkingPeriod.new(:track_id => 1, :start => Date.today, :finish => Date.today + 30, :reported_grade_id => 1)
    @last_mp = MarkingPeriod.new(:track_id => 1, :start => Date.today + 31, :finish => Date.today + 60, :reported_grade_id => 2)
  end
end

