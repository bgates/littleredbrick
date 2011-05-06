module AccountUploadHandler

  def accounts_from_upload(hash = params, override = {})
    @upload ||= AccountUpload.open("#{current_user.id}_#{@type}#{hash[:extension]}")
    @upload.import_users(hash, @type, @school, override)
  end

  def get_users_from(details)
    type = 'staffers' if type == 'administrators'
    type = Object.const_get(@type.chomp('s').capitalize)
    users = details.map{|n, user| type.default(user.merge(:school_id => @school.id))}
    users.partition{|u| u.save}
  end

  def no_names?
    params[:details].delete_if{|k,v| v[:first_name] ==  '' && v[:last_name] == ''}
    params[:details].empty? && !flash[:pending_import]
  end

  def set_names_by_flash
    override = (flash[:substitutes] || []) + params[:details].values
    @saveable, @new_people, @substitutes = accounts_from_upload(flash[:pending_import],  override)
  end

  def set_saveable_and_new
    if no_names?
      flash.now[:error] = "Please enter at least one name."
    elsif flash[:pending_import]
      set_names_by_flash
    else
      @saveable, @new_people = get_users_from(params[:details])
      @substitutes = []
    end
  end

end
