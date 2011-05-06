module GradeScale

  DEFAULT = [[(-1.0 / 0)...60, 'F'], [60...70, 'D'], [70...80, 'C'], [80...90, 'B'], [90..(1.0 / 0), 'A']]

  def self.included(base)
    base.before_validation          :check_grade_scale, :on => :update
    base.serialize                  :grade_scale

    base.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods

    def grade_ranges
      grade_scale.map{|g| g[0]}
    end

    def grade_scale
      super || GradeScale::DEFAULT
    end

    def grade_scale_bounds
      grade_scale.map{|elements| elements.first.last}
    end

    def grade_scale_grades
      grade_scale.map{|elements| elements.last}
    end

    def grade_scale=(params)
      return nil if params.blank? || params[:grades].blank? || params[:bounds].blank? #stupid line that department_test#test_enrollment needs
      params[:grades].each_with_index do |g, i|
        if g.blank?
          params[:grades].delete_at(i); params[:bounds].delete_at(i)
        end
      end
      scale = [[(-1.0 / 0)...params[:bounds].shift.to_i, params[:grades].shift]]
      params[:bounds].each_index do |i|
        scale << [scale.last.first.last...params[:bounds][i].to_i, params[:grades][i]]
      end
      scale << [scale.last.first.last...(1.0 / 0) , params[:grades].last]
      super(scale)
    end

    def on_scale(grade)
      begin
        grade_scale.detect{|range, letter| range.include?(grade)}[1]
      rescue
        '-'
      end
    end

    protected

      def check_grade_scale
        errors.add(:grade_scale, 'needs at least two grades') and return false unless grade_scale_grades.uniq.compact.length > 1
        errors.add(:grade_scale, "needs to have the grade ranges entered in order.") unless grade_scale_bounds == grade_scale_bounds.sort
        errors.add(:grade_scale, "needs all grades to be unique.") unless grade_scale_grades.sort == grade_scale_grades.uniq.sort
      end

  end
end
