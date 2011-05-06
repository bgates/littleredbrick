class People::AdministratorsController < ApplicationController
  before_filter :login_required
  before_filter :find_admin, :except => [:index, :new, :create, :search]
  layout :initial_or_by_user

  def index
    @admins = @school.admins.sort_by{|a|a.last_name}
  end

  def show
    @logins = Login.scoped_by_user_id(@admin.id).paginate :per_page => 10, :page => params[:page], :order => 'created_at desc'
  end

  def edit

  end

  def update
    if @admin.update_attributes(params[:admin])
      flash[:notice] = "<h2>Good News</h2>#{@admin.display_name}&#39;s account has been updated."
      redirect_to administrators_path
    else
      render :action => "edit"
    end
  end

  def new
    @admin = Staffer.new
  end

  def create
    @admin = params[:admin].blank?? @school.teachers.find(params[:id]).make_admin : @school.staffers.create(params[:admin])
    if @admin.valid?
      flash[:notice] = "<h2>Good News</h2>#{@admin.full_name} was added as an administrator."
      respond_to do |format|
        format.html{redirect_to administrators_path}
        format.js{render :update do |page| page.redirect_to administrators_path end }
      end
    else
      render :action => "new"
    end
  end

  def search
    @teachers = Teacher.search(params[:search], :school_id => @school.id)
    respond_to do |wants|
      wants.html{@admin = Staffer.new; render :action => 'new'}
      wants.js{render :action => 'search_results', :layout => false}
    end
  end

  def destroy
    if @admin.id == current_user.id
      flash[:error] = '<h2>You Can&#39;t Do That</h2>You are not allowed to' + (@admin.is_a?(Teacher)? ' revoke your own administrative privileges.' :
      ' delete yourself from the system.')
    else
      if @admin.revoke_admin
        flash[:notice] = "<h2>Good News</h2>#{@admin.display_name} " + (@admin.is_a?(Teacher)? 'no longer has admin privileges.' : 'was removed from the system.')
      else
        flash[:error] = "<h2>Bad News</h2>Something went wrong, and #{@admin.display_name} "  + (@admin.is_a?(Teacher)? 'still has admin privileges.' : 'was not deleted.')
      end
    end
    respond_to do |format|
      format.html{redirect_to administrators_path}
      format.js{render :update do |page| page.redirect_to administrators_path end }
    end

  end
private

  def find_admin
    @admin = @school.admins.find(params[:id])
  end
end
