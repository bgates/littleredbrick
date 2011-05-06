class Catalog::CatalogsController < ApplicationController
  before_filter :login_required
  layout 'initial'

  def new
    @school.set_generic_departments
  end

  def create
    create_or_update
  end
  
  def edit
    params[:extra].to_i.times{|n| @school.departments.build }
  end

  def update
    create_or_update
  end

protected
  
    def authorized?
      super && session[:initial]
    end

    def create_or_update
      @school.update_attributes(params[:school])
      if @school.departments.all?{|d|d.valid? }
        redirect_to home_url, :notice => msg
      else
        render action_name == 'create' ? 'new' : 'edit'
      end
    end
end
