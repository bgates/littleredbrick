class AccountsController < ApplicationController
  layout :initial_or_by_user
  before_filter :login_required, :except => [:forgot_password, :reset_password]
  before_filter :keep_flash
  skip_filter :set_back

  def edit
    @user = current_user
    prepare_children
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user]) && !@user.has_invalid_children? 
      flash[:notice] = "<h2>Good News</h2>Your account info was updated successfully."
      flash.discard(:show_initial_layout)
      redirect_to home_url
    else
      prepare_children
      render :action => "edit"
    end
  end

  def forgot_password
    render :layout => 'login'
  end

  def reset_password
    @school = School.find(@school) #domain_finder might be overoptimized
    @user = @school.users.find_by_email(params[:email])
    if @user
      UserNotifier.password_bypass(@school, @user).deliver
      flash[:notice] = "<h2>Check your email</h2>A notice has been sent to your email account to let you log in to LittleRedBrick"
      redirect_to login_url
    else
      flash[:error] = "<h2>Bad News</h2>We couldn&#39;t find your account under the email and name your provided. You can try again, or contact a school administrator to reset your password for you."
      render :action => "forgot_password", :layout => 'login'
    end
  end

private
  def initial_or_by_user
    first_login?? 'initial' : by_user #this is different from the other ctrlrs that need to check on session[:initial] to see if initial layout should be provided, bc account/edit can be seen by all users
  end

  def first_login?
    @first ||= (flash[:show_initial_layout] || session[:initial])
  end

  def prepare_children
    @kids = @user.existing_and_new_children if @user.is_a?(Parent)
  end

  def keep_flash
    flash.keep(:show_initial_layout)
  end
end

