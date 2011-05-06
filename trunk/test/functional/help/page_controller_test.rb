require 'test_helper'

class Help::PageControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns(true)
  end

  def test_find_beast_help_pages #no help for monitorships
    %w(forums moderators posts topics users).each do |controller|
      "Beast::#{controller.capitalize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
      next if beast_exception_for(controller, method)
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end

  def test_catalog_help
    %w(departments subjects).each do |controller|
      "Catalog::#{controller.capitalize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
      next if %w(setup_catalog revise_catalog destroy rescue_action).include?method
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end

  def test_gradebook_help
    %w(assignments gradebook marks enrollment seating_chart).each do |controller|
      "Gradebook::#{controller.camelize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
        next if gradebook_exception_for(controller, method)
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end

  def test_people_help #no help for enter, or included actions (select file, etc)
    %w(administrators teachers students parents).each do |controller|
      "People::#{controller.capitalize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
        next if %w(destroy rescue_action).include?(method)
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end

  def test_term_help
    %w(terms marking_periods reported_grades tracks).each do |controller|
      "Term::#{controller.camelize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
        next if term_exception_for(controller, method)
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end

  def test_front_page_help
    get :display, :action_name => 'home', :controller_name => 'front_page'
    assert_redirected_to general_help_url('index')
  end
  
  def test_other_controllers_help
    %w(accounts events schools sections student teaching_load).each do |controller|
      "#{controller.camelize}Controller".constantize.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.map(&:to_s).each do |method|
        next if exception_for(controller, method)
        @request.session[:school] = @request.session[:user] = :exists
        get :display, :action_name => method, :controller_name => controller
        assert_response :success
      end
    end
  end
  protected
  def beast_exception_for(controller, method)
    %w(destroy rescue_action).include?(method) || 
    (controller == 'moderators' && %w(update search).include?(method)) ||
    (controller == 'posts' && method == 'show') ||
    (controller == 'topics' && method == 'index') ||
    (controller == 'users' && method == 'admin') 
  end

  def gradebook_exception_for(controller, method)
    %w(destroy rescue_action).include?(method) ||
    (controller == 'gradebook' && %w(update import_grades).include?(method))||
    (controller == 'rollbook' && method == 'import_enrollment')
  end

  def term_exception_for(controller, method)
    %w(destroy rescue_action).include?(method) ||
    (controller == 'terms' && method == 'index')
  end

  def exception_for(controller, method)
    %w(destroy rescue_action).include?(method) ||
    (controller == 'accounts' && %w(forgot_password reset_password).include?(method)) ||
    (controller == 'schools' && %w(new create).include?(method)) ||
    (controller == 'sections' && %w(new create).include?(method)) ||
    (controller == 'teaching_load' && %w(set_departments import_teaching_assignments).include?(method))
    
  end
end
