class Track < ActiveRecord::Base
  belongs_to               :term
  has_many                 :marking_periods, :order => 'start', :dependent => :destroy
  has_many                 :sections, :dependent => :destroy
  acts_as_list             :scope => :term
  validates_presence_of    :term_id

  after_create             :add_marking_periods
  attr_accessor            :duration, :initial
  validates_associated     :marking_periods
  after_update             :save_marking_periods
  validate                 :check_archive_date, :on => :update
  after_validation         :tidy_errors
  before_validation        :initialize_marking_periods, :on => :create
  validate                 :prevent_overlap

  def add_marking_periods
    return true unless marking_periods.empty?
    term.marking_periods.each do |mp|
      self.duration ||= 30
      self.initial ||= Date.today
      marking_periods.create(:reported_grade_id => mp.id, :duration => duration, :initial => initial)
    end
  end

  def classes_after?(period)
    sections.any?{ |s| s.time && s.time > period }
  end

  def check_archive_date
    if archive && archive < finish
      errors.add(:archive, 'must come after the end of the last marking period')
    end
  end

  def current_marking_period
    marking_periods.reverse.detect{|mp| mp.start <= Date.today} || marking_periods.first
  end

  def existing_marking_periods=(mp_attributes)
    marking_periods.each do |mp|
      attr = mp_attributes[mp.id.to_s].merge(:skip_sequence_validation => true)
      if attr
        mp.attributes = attr
      end
    end
  end

  def finish
    marking_periods.last.finish 
  end

  def new_marking_periods=(mp_attributes)
    mp_attributes.each_with_index do |attr, i|
      marking_periods.build(attr.merge(:position => i + 1))
    end
  end

  def occupied?
    sections.count(:conditions => 'enrollment > 0') > 0
  end

  def save_marking_periods
    marking_periods.each{|mp| mp.save(:validate => false)}
  end

  def start
    marking_periods.first.start
  end

  def self.current_marking_period(marking_periods)
    marking_periods.sort_by(&:position).reverse.detect{|mp| mp.start <= Date.today} || marking_periods.sort_by(&:position).first
  end

  protected

    def initialize_marking_periods
      rpg = term.marking_periods
      marking_periods.each_with_index do |mp, i|
        mp.reported_grade_id = rpg[i].id
      end
    end

    def prevent_overlap #allow :start and :finish blank here b/c validates_associated picks them up
      @flag = false
      marking_periods.each do |mp|
        next if mp == marking_periods.first
        prev = marking_periods[marking_periods.index(mp) - 1]
        if mp.start && prev.finish && mp.start < prev.finish
          mp.errors.add(:start)
          @flag = true
        end
      end
      errors.add(:base, 'The marking periods for a track cannot overlap. Please make sure no marking period starts before the previous marking period ends.') if @flag
    end

    def tidy_errors
      errors[:marking_periods].delete_if{|e| e == 'is invalid'}
    end
end

