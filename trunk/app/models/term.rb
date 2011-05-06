class Term < ActiveRecord::Base
  belongs_to              :school
  has_many                :tracks, :dependent => :destroy
  has_many                :reported_grades, :as => :reportable, 
                          :dependent => :destroy
  has_many                :sections, :through => :tracks, 
                          :dependent => :destroy
  attr_accessor           :n_marking_periods, :n_tracks, :start, :finish
  validates_format_of     :start, :finish, :with => /\d{4}-\d{2}-\d{2}/,
                          :message => "must be in date format (yyyy-mm-dd)",
                          :on => :create
  validate                :duration, :on => :create
  validate                :periods
  before_validation       :set_first_period, :on => :create
  after_create            :create_marking_periods

  def end_date
    tracks.last.finish
  end

  def multitrack?
    tracks.count > 1
  end

  def marking_periods
    reported_grades.select{|g| g.description =~ /Marking Period/}.sort_by(&:id)
  end
    
  def reported_grades_with_sort
    ReportedGrade.sort(reported_grades)
  end
  
  def start_date
    tracks.first.start
  end
  
  protected

  def check_class_time
    if tracks.any?{ |t| t.classes_after?(high_period) }
      errors.add(:high_period, 
                 ': There are sections assigned to a later period') 
    end
  end

  def check_period_order
    if low_period > high_period
      errors.add(:high_period, ': Last period must come after first') 
    end
  end

  def create_marking_periods
    self.n_tracks = 1 if self.n_tracks.to_i == 0
    n_marking_periods.to_i.times{|n| reported_grades.create(:description => 'Marking Period', :allowed => true)}
    start, finish = Date.civil(*self.start.split('-').map{|n|n.to_i}), Date.civil(*self.finish.split('-').map{|n|n.to_i})
    duration = ((finish - start) / n_marking_periods.to_i).to_i
    n_tracks.to_i.times{|n| tracks.create(:duration => duration, :initial => start)}
  end

  def duration
    if start.is_a?(Date) && finish.is_a?(Date) #only for tests
      errors.add(:finish, 'must be later than the start') if start >= finish
    else
      begin
        errors.add(:finish, 'must be later than the start') if Date.parse(start) >= Date.parse(finish)
      rescue
        errors.add(:finish, 'must be later than the start')
      end
    end
  end

  def periods
    if low_period && high_period
      check_period_order
      check_class_time
    elsif low_period.nil? ^ high_period.nil?
      errors.add(:low_period, '^First period must be set if last period is') if  high_period
      errors.add(:high_period, '^Select a number for the last period in the day, or the maximum number of classes per teacher') if low_period
    end
  end

  def set_first_period
    self.low_period ||= 1
  end
end
