require 'active_model'
class SeatingChart
  include ActiveModel::Validations

  validate :check_uniqueness_and_completeness
  def initialize(section, seats)
    @section = section
    @seats = seats
  end

  def save
    return unless valid?
    @seats.each do |x, row|
      row.each do |y, entry|
        next unless rbe = @section.rollbook_entries.detect{|r| r.id == entry.to_i}
        rbe.x = x
        rbe.y = y
        rbe.save
      end
    end
  end

  protected

  def check_uniqueness_and_completeness
    no_duplicates
    no_missing
  end

  def no_duplicates
    named = @seats.values.map(&:values).flatten.reject{|n| n.blank?}
    if named != named.uniq
      dups = named.sort!.select{|rbe| rbe == named[named.index(rbe) + 1]}.uniq
      students = @section.rollbook_entries.select{|rbe| dups.include?(rbe.id.to_s)}.map(&:student).map(&:full_name)
      errors.add(:base, "#{students.to_sentence} appeared on the chart more than once.")
    end
  end

  def no_missing
    named = @seats.values.map(&:values).flatten.reject{|n| n.blank?}
    errors.add(:base, "At least one student&#39;s name is missing from the chart.") unless named.length == @section.enrollment
  end
end

