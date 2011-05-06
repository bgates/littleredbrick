class Upload::TeacherSchedulesController < UploadController

  protected

  def import
    @upload = TeachingUpload.open("#{current_user.id}_teacher_schedules#{params[:extension]}")
    created_sections = @upload.create_sections(params[:current], @school)
    if @upload.valid?
      flash[:notice] = "<h2>Good News</h2>#{created_sections} sections were created for your teachers. If you were expecting more than that, go back to the teachers&#39; page and look for the missing ones."
      flash[:notice] += " Remember that all sections were added into one track. You (or every teacher) will have to assign the sections to their correct track manually." if @school.terms.first.tracks.length > 1
      redirect_to session[:initial] ? home_path : teachers_path
    else
      @data = @upload.data
      render :action => "describe_file"
    end
  end

  def controller_specific_msg
    'Confirm that the first column of this file contains either teacher names or ID numbers, and all other columns have teaching assignments for each teacher.'
  end

end

