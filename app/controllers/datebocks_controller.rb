class DatebocksController < ApplicationController
  def index
  end

  def help
    @d = Date.today
    render :partial => 'datebocks/help'
  end
end