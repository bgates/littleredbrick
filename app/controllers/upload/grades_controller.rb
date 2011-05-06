class Upload::GradesController < UploadController

  protected
  def import
    @upload = GradeUpload.open("#{current_user.id}_gradebook#{params[:extension]}")
    @upload.prepare_grades(@section,params)
    if @upload.valid?
      if (updated_grades = @upload.update_all).all?{|g|g.valid?}
        flash[:notice] = "<h2>Good News</h2>Gradebook was successfully updated" + notice_of_missing_students
      else
        flash[:error] = "<h2>Bad News</h2>There was a problem updating the grades. Any invalid uploaded grade was not saved."
        flash[:bad_grades] = updated_grades.collect{|g| g.id unless g.valid?}.compact
      end
      redirect_to section_gradebook_path(@section)
    else
      set_controller_specific_vars
      @data = @upload.data
      render :action => 'describe_file'
    end
  end

  def authorized?
    @teacher = current_user
    @teacher.is_a?(Teacher) && @section = @teacher.sections.find_by_id(params[:section_id], :include => [:subject, {:rollbook_entries => :student}])
  end     

  def notice_of_missing_students
    missing_ids = @section.rollbook_entry_ids - @upload.collect_students.compact
    return '' if missing_ids.empty?
    missing = missing_ids.map do |id|
      @section.rollbook_entries.detect{|rbe| rbe.id == id}
    end
    ", however, the following students were not found in the file: #{missing.map{|rbe| rbe.student.full_name}.to_sentence}"
  end

  def controller_specific_msg
    'For each column, please indicate its assignment number, or if it should be ignored.'
  end
  
  def set_controller_specific_vars
    @assignments = params[:older].nil?? @section.assignments.limit(10).order('position DESC') : @section.assignments.order('position DESC')
  end
end
