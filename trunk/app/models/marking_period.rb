class MarkingPeriod < ActiveRecord::Base
  belongs_to                       :track
  acts_as_list                     :scope => :track
  belongs_to                       :reported_grade
  validates_format_of              :start, :finish, :with => /\d\d\d\d-\d\d-\d\d/,
                                   :message => "must be in date format (yyyy-mm-dd)"
  validates_presence_of            :reported_grade_id
  attr_accessor                    :duration, :initial, :skip_sequence_validation, :previous
  before_validation                :set_dates, :on => :create
  validate                         :start_and_finish_and_archive
  validate                         :marking_period_ordering, :on => :update
  validate                         :check_previous

  def set_dates
    if self.duration && self.new_record?
      start = track.marking_periods.empty?? self.initial : track.marking_periods[-1].finish + 1
      finish = duration.nil?? start + 30 : start + duration
      self.start, self.finish = start.strftime("%Y-%m-%d"), finish.strftime("%Y-%m-%d")
    end
    true
  end

  def name
    reported_grade.description
  end

  def self.on_calendar(track_or_tracks, cal_start, cal_finish)
    dates = []#dates within the month
    tracks = [track_or_tracks].flatten
    marking_periods = MarkingPeriod.where(['((start BETWEEN ? AND ?) OR (finish BETWEEN ? AND ?)) AND track_id IN (?)', cal_start, cal_finish, cal_start, cal_finish, tracks.map(&:id)])
    marking_periods.each do |mp|
      if (cal_start..cal_finish).include?(mp.start)
        dates << Event.new(:name => "Begin Marking Period #{mp.position}#{track_check(tracks, mp)}", :date => mp.start)
      end
      if (cal_start..cal_finish).include?(mp.finish)
        dates << Event.new(:name => "End Marking Period #{mp.position}#{track_check(tracks, mp)}", :date => mp.finish)
      end
    end
    dates
  end

  protected
  def self.track_check(tracks, mp)
    if tracks.length > 1
      track = tracks.detect{|t| mp.track_id == t.id}
      "(Track #{track.position})"
    end
  end

  def start_and_finish_and_archive
    if start && finish && start > finish
      errors.add(:finish, 'must be after start date')
    end
    if finish && track && track.archive && finish > track.archive
      errors.add(:finish, 'must be before the track is archived')
    end
  end

  def marking_period_ordering
    return true if skip_sequence_validation
    tmp = track.marking_periods(true)
    return if tmp.empty?
    unless id == tmp.collect(&:id).min
      previous = tmp[tmp.index(tmp.detect{|mp|mp.id == id}) - 1]
      if start && previous.finish && start < previous.finish
      errors.add(:start, "must be after end date of previous marking period")
      end
    end
    unless id == tmp.collect(&:id).max#tmp.last.id == id
      subsequent = tmp[tmp.index(tmp.detect{|mp| mp.id == id}) + 1]
      if finish && subsequent.start && finish > subsequent.start
        errors.add(:finish, "must be before start date of subsequent marking period")
      end
    end
  end

  def check_previous
    errors.add 'start', 'must be after end date of previous marking period' unless start.nil? || previous.nil? || start > previous
  end
end

