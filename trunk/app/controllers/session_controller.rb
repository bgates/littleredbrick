class SessionController < ApplicationController
  layout 'login'
  skip_filter :find_child, :only => :update
  before_filter :login_required, :only => [:destroy, :update]
  
  def create
    cookies[:use_open_id] = {:value => '0', :expires => 1.year.ago.utc}
    password_authentication params[:login], params[:password]
  end

  def new
    flash.now[:notice] ||= session[:erste] 
    @hide = params[:hide_id]
  end

  def destroy
    current_user.logins.find(:last).update_attribute(:logout, Time.now)
    session.clear
    cookies.delete :login_token
    redirect_to login_path, :notice => msg
  end

  def bypass
    if @auth = @school.authorizations.find_by_crypted_password(params[:id].reverse)
      current_user = @auth.user
      redirect_to edit_account_url 
    else
      redirect_to login_path
    end
  end

  def update
    if current_user.is_a?Parent
      session[:child] = current_user.children.find(params[:child]).id
    else
      current_user.admin = session[:admin] = toggle_status
    end
    redirect_to home_url, :notice => msg
  end

  protected

    def password_authentication(name, password)
      if self.current_user = Authorization.authenticate(name, password, @school.id)
        successful_login
      else
        failed_login "Invalid login or password, try again please."[:invalid_login_message]
      end
    end

    def successful_login
      set_cookie
      redirect_to CGI.unescape(params[:to]) and return if params[:to]
      if current_user.logins.length == 1 && !session[:erste]
        flash[:notice] = "<h2>You should probably change your login</h2>You will be able to get back to this screen later, but I wanted to let you get it out of the way now"
        flash[:show_initial_layout] = true
        redirect_to edit_account_path and return
      end
      if current_user.is_a?(Parent)
        if current_user.children.length == 1
          session[:child] = current_user.children[0].id
        else
          redirect_to session_path and return
        end
      end
      redirect_back_or_default home_url
    end

    def toggle_status
      current_user.is_a?(Teacher) && current_user.admin? && 
      session[:admin].blank?
    end

    def failed_login(message)
      flash.now[:error] = message
      render :action => 'new'
    end

    def set_cookie
      cookies[:login_token] = {:value => "#{current_user.id};#{@school.id};#{current_user.authorization.reset_login_key!}", :expires => 1.year.from_now.utc} if params[:remember_me] == "1"
    end

    def root_url() home_url; end
end
