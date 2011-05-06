class Help::GeneralController < ApplicationController
  before_filter :login_required
  layout :initial_or_by_user_unless_its_a_video

  def display
    render "help/general/#{path}"
  end
  
  def video
    @its_a_video = true
    show_video
  end

  protected
   
    def authorized?
      true#TODO that's not right
    end

    def subfolder_template
      params[:action_name] = "index" if subfolder_required?
      "/#{params[:action_name]}" unless params[:action_name].blank?
    end

    def path
      @path = case params[:controller_name]
      when 'subject_menu'
        'subject_menu' 
      when 'video_menu'
        choice = current_user.is_a?(Teacher) && session[:admin] ? 'staffer' : current_user.class.to_s.downcase
        "video_menu_#{choice}"  
      when nil
        current_user.is_a?(Staffer)? "index" : "student_view" 
      else
        "#{params[:controller_name]}#{subfolder_template}" 
      end
    end

    def prep_tour_if_appropriate
      if params[:id] == 'tour'
        @video = 
        case current_user.class.to_s
        when 'Staffer'
          'intro'
        when 'Teacher'
          if current_user.sections.empty?
            'setup_new'
          elsif current_user.sections.all?{|s| s.enrollment == 0}
            'setup_post_class'
          else
            'setup_post_enrollment'
          end
        else #this used to be when 'teacher' again, which would have wiped out the above 3
          'tour'
        end
      end
    end

    def show_video
      prep_tour_if_appropriate
      @path = 'Video'
      render :action => "video", :layout => false 
    end

    def subfolder_required?
      %w(discussions setup).include?(params[:controller_name]) &&
      params[:action_name].blank?
    end

    def initial_or_by_user_unless_its_a_video
      initial_or_by_user unless @its_a_video
    end
end
