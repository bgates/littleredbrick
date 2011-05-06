class Absence < ActiveRecord::Base
  belongs_to :rollbook_entry
  belongs_to :section
  belongs_to :student
  before_update :destroy, :if => Proc.new {|abs| abs.code.blank? }

  CODES = {0 => 'Tardy', 1 => 'Illness (Excused)', 2 => 'Other (Excused)', 3 => 'Unexcused'}

  SHORT_CODE = {0 => 'T', 1 => 'I', 2 => 'X', 3 => 'U'}

  class << self 
    def parent_notice(absences, sections)
      day_total, period_total = summary(sections, absences)
      day_ex, day_unex = partition_by_excused(day_total)
      pd_ex, pd_unex = partition_by_excused(period_total)
      {:excused_days => day_ex, :excused_periods => pd_ex, :unexcused_days => day_unex, :unexcused_periods => pd_unex}
    end

    def summary(sections, absences)
      day_total, period_total = Hash.new(0), Hash.new(0)
      day_length = sections.all?{|s| s.time.blank?} ? sections.length : sections.map(&:time).uniq.length
      absences.group_by(&:date).each do |date, group|
        if absent_not_tardy_all_day?(group, day_length)
          code = group.first.code
          day_total[code] += 1
        else
          group.each{ |abs| period_total[abs.code] += 1 }
        end
      end
      [day_total, period_total]
    end

    protected

    def absent_not_tardy_all_day?(absences, day_length)
      absences.length >= day_length && 
      absences.map(&:code).uniq.length == 1 && 
      absences.first.code > 0
    end
    
    def partition_by_excused(absences)
      excused, unexcused = {}, {}
      absences.each do |k,v|
        if k == 0 || k == 3
          unexcused[k] = v
        else
          excused[k] = v
        end
      end
      [excused, unexcused]
    end
  end
end
