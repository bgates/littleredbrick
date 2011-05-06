class Upload::EnrollmentController < UploadController
  before_filter :find_sections, :only => %w(create)

  protected

  def import
    @upload = EnrollmentUpload.open("#{current_user.id}_enrollments#{params[:extension]}")
    if @enrollment = @upload.create_enrollment(@teacher, params)
      flash[:notice] = "<h2>Good News</h2>#{@enrollment} students have been added to #{params[:section].delete_if(&:blank?).length}  classes. If you were expecting more than that, go to each class&#39; page to see who is missing."
      flash[:notice] += ' To create an assignment for a class, click the "Gradebook" link under its name.' if current_user == @teacher
      redirect_to(current_user == @teacher ? sections_path : teachers_path)
    else
      find_sections
      @data = @upload.data
      render :action => "describe_file"
    end
  end

  def authorized?
    @section = Section.find(params[:section_id], :include => [:teacher, {:subject => :department}])
    @teacher = @section.teacher
    super || current_user.teaches?(@section)
  end

  def controller_specific_msg
    'Each column of this file should contain student names or ID numbers for a class. Please specify the class for each column, and the kind of data in the file (name or ID).'
  end

  def find_sections
    @sections = @teacher.sections.includes(:subject)
  end

end

