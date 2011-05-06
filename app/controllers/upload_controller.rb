class UploadController < ApplicationController
  before_filter :login_required
  layout :initial_or_by_user

  def new
    @upload = Upload.new
  end

  def create
    if params[:extension].blank?
      upload 
    else
      import
    end
  end

  protected

  def upload
    @upload = Upload.create((params[:upload] || {}).merge(:type => type, :user => current_user.id))
    if @upload.valid?
      set_controller_specific_vars
      @data = @upload.data
      flash.now[:notice] = "<h2>Good News</h2>The file was uploaded successfully. #{controller_specific_msg}" 
      render "describe_file"
    else
      render "new"
    end
  end

  def set_controller_specific_vars;end

  def type
    @type || controller_name
  end
end

