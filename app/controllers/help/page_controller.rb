class Help::PageController < ApplicationController
  layout :initial_or_by_user

  def display
    redirect_to general_help_path("index") and return if front_page?
    render 'help/page/assignments/show' and return if params[:controller_name] == 'events' && params[:action_name] == 'assignment'
    render "help/page/#{params[:controller_name]}/#{real_action}"

  end

  protected

  def real_action
    case params[:action_name].to_s
    when 'create'
      'new'
    when 'update'
      'edit'
    else params[:action_name]
    end
  end

  def front_page?
    params[:controller_name] == 'front_page' && params[:action_name] == 'home'
  end
end

