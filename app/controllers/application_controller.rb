class ApplicationController < ActionController::Base
  init_gettext "beast" if Object.const_defined?(:GetText)
  include AuthenticatedSystem, SectionPreparation
  clear_helpers

  rescue_from ActiveRecord::RecordInvalid do
    render_invalid_record 
  end

  helper_method :current_user, :current_user=, :logged_in?, :admin?, :last_active, :method_missing

  before_filter  :domain_finder, :style_setter, :find_child

  after_filter :set_back

  protected

    def authorized?
      %w(accounts datebocks front_page search session).include?(controller_name) || current_user.admin?  
    end

    def domain_finder
      session[:school] ||= (@school = School.find_by_domain_name(request.subdomains[0])) ? @school.id : nil
      if session[:user]
        self.current_user = set_user
        @school = @current_user.nil?? nil : @current_user.school
      else
        @school = School.find(session[:school], :select => :id)
      end
    rescue
      redirect_to 'http://schoolfinder.littleredbrick.com/schools/search' and return false
    end

    def style_setter
      session[:style] = params[:stylesheet] if params[:stylesheet]
    end

    def set_back
      session[:return_to] = request.fullpath if request.get?
    end

    def set_user
     User.where(['users.id = ? AND school_id = ?', session[:user], session[:school]]).includes([:school, :roles]).first
    end

    def find_child
      if current_user.is_a?(Parent)
        @student = session[:child] ? current_user.children.find(session[:child]) : current_user.children.first
        current_user.child = @student
      end
    end

    def help
      Helper.instance
    end

    def msg(type = :notice)
      view_context.msg(type)
    end

    class Helper
      include Singleton
      include ActionView::Helpers::TextHelper
    end

    #session :session_key => '_beast_session_id'

    def render_invalid_record
      render (action_name == 'create' ? 'new' : 'edit')
    end

    def initial_or_by_user
      session[:initial] ? 'initial' : by_user
    end

    def by_user
      (session[:admin] || current_user.is_a?(Superuser)) ? 'staffer' : current_user.class.to_s.downcase
    end

end

