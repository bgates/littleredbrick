class Help::FaqController < ApplicationController
  layout :by_user

  def display
    render "help/faq/#{params[:action_name] || 'index' }" 
  end
end
