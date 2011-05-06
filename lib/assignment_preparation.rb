module AssignmentPreparation
  protected
  
  def set_assignment_conditions
    params.delete_if{|k,v| v == ''}
    conditions, array = "assignments.section_id = ? ", [@section.id]
    if (params[:first].blank? && params[:last].blank?)
      if params[:mp].blank?
        conditions += " AND assignments.reported_grade_id = ?"
        array << @section.current_marking_period.reported_grade_id
      else
        mps = MarkingPeriod.find(:all, :conditions => ['track_id = ? AND position IN (?)', @section.track_id, (Array params[:mp]).map(&:to_i)], :select => 'reported_grade_id')
        (conditions += " AND assignments.reported_grade_id IN (?)"; array << mps.map(&:reported_grade_id))
      end
    end
    (conditions += " AND category IN (?)"; array << params[:cat]) unless params[:cat].blank?
    (conditions += " AND position BETWEEN ? AND ?"; array << params[:first] << params[:last]) unless params[:first].blank? || params[:last].blank?
    (conditions += " AND point_value BETWEEN ? AND ?"; array << params[:low] << params[:high]) unless params[:high].blank? || params[:low].blank?
    (conditions += " AND (assignments.date_due BETWEEN ? AND ? OR grades.date_due BETWEEN ? AND ?)"; array << params[:start] << params[:finish] << params[:start] << params[:finish]) unless params[:start].blank? || params[:finish].blank?
    [conditions, array]
  end

  def set_assignment_variables
    @mp_position = MarkingPeriod.find_by_track_id_and_reported_grade_id(@section.track_id, @assignment.reported_grade_id).position
    @students = @section.students.find(:all, :include => :rollbook_entries)
    @grades = @assignment.grades.index_by{|grade| @students.detect{|s|s.rollbook_entries.map(&:id).include?(grade.rollbook_entry_id)}.id}
    @category_points = Assignment.sum('point_value', :conditions => ["section_id = ? AND category = ? AND reported_grade_id = ?", @section.id, @assignment.category, @assignment.reported_grade_id])
    @mp_points = Assignment.sum('point_value', :conditions => ["section_id = ? AND reported_grade_id = ?", @section.id, @assignment.reported_grade_id])
  end
end
