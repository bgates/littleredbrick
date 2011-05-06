module AuthenticatedSystem
  protected

    def authorized?
      true
    end

    # Check whether or not to protect an action.
    #
    # Override this method in your controllers if you only want to protect
    # certain actions.
    #
    # Example:
    #
    #  # don't protect the login and the about method
    #  def protect?(action)
    #    if ['action', 'about'].include?(action)
    #       return false
    #    else
    #       return true
    #    end
    #  end
    def protect?(action)
      true
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required

    def login_required
      login_by_token      unless logged_in?
      login_by_basic_auth unless logged_in?
      access_denied unless logged_in? && authorized?
    end

    def login_by_token
      self.current_user = User.find_by_id_and_school_id_and_login_key(*cookies[:login_token].split(";")) if cookies[:login_token] and not logged_in?
    end

    @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
    def login_by_basic_auth
      auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
      auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
      self.current_user = User.authenticate *Base64.decode64(auth_data[1]).split(':')[0..1].push(@school.id) if auth_data && auth_data[0] == 'Basic'
    end
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to  login_path
        end
        format.js   { render(:update) { |p| p.redirect_to login_path } }
        format.xml  do
          headers["WWW-Authenticate"] = %(Basic realm="Beast")
          render :text => "HTTP Basic: Access denied.\n", :status => :unauthorized
        end
      end
        #respond_to do |accepts|
        #accepts.html do
        #  store_location
        #  redirect_to :controller => '/account', :action => 'login'
        #end
        #accepts.xml do
        #  headers["Status"]           = "Unauthorized"
        #  headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        #  render :text => "Could't authenticate you", :status => '401 Unauthorized'
        #end
      #end
      false
    end
    def current_user=(value)
      if @current_user = value
        session[:user] = @current_user.id#used to be session[:user_id]
        # this is used while we're logged in to know which threads are new, etc
        #session[:last_active] = @current_user.last_seen_at
        session[:topics] = session[:forums] = {}
        #update_last_seen_at
      end
    end

    def current_user
      @current_user ||= ((session[:user] && User.find_by_id(session[:user])) || 0)
    end

    def logged_in?
      current_user != 0
    end

    #def update_last_seen_at
    #  return unless logged_in?
    #  User.update_all ['last_seen_at = ?', Time.now.utc], ['id = ?', current_user.id]
    #  current_user.last_seen_at = Time.now.utc
    #end
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.fullpath
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      (session[:return_to] && session[:return_to] != login_path) ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?
    end

    # When called with before_filter :login_from_cookie will check for an :auth_token
    # cookie and log the user back in if apropriate
end
