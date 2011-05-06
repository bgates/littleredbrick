class Upload::UsersController < UploadController
  before_filter :find_type
  include AccountUploadHandler

  protected

  def import
    @upload = AccountUpload.open("#{current_user.id}_#{@type}#{params[:extension]}")
    unless names_accounted_for?
      flash.now[:error] = "<h2>Problem</h2>In order to create #{@type} accounts from a spreadsheet file, the file must have both first and last names. Use the select boxes at the bottom of the table to indicate which columns have names in them."
      @data = @upload.data
      set_controller_specific_vars
      render :action => "describe_file" and return
    end
    @saveable, @new_people, @substitutes = accounts_from_upload
    @new_people += @substitutes
    return_path = session[:initial] ? home_path : send("#{@type}_path")
    if @new_people.empty? 
      flash[:import] = {:type => @type, :number => @saveable.length}
      redirect_to return_path, :notice => msg
    else
      flash[:pending_import] = params
      @page_title = "Correct Duplicate Logins"
      render :template => "people/enter/details"
    end
  end
 
  def controller_specific_msg
    'Please identify the kind of data in each column.'
  end

  def find_type
    @type = params[:id]
    @type = 'students' unless %w(teachers students staffers).include? @type
    @school = School.find(@school.id)
    @low, @hi = @school.low_grade, @school.high_grade
  end

  def names_accounted_for?
    v = params[:import].values
    (v.include?('last_name') && v.include?('first_name')) || 
     v.include?('full_name') || v.include?('last_first')
  end

  def set_controller_specific_vars
    @columns = %w(First\ Name Last\ Name Name(last,first) Full\ Name ID) 
  end
end
