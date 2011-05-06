class BeastController < ApplicationController
  before_filter :set_discussable
  before_filter :login_required
  layout        :by_user

  def find_or_initialize_discussable(scope)
    return unless scope
    scope = scope.id if scope.respond_to? :id 
    if scope.to_i.to_s == scope.to_s
      Section.find(scope)
    elsif %w(school admin teachers staff parents).include?(scope) || !scope
      @school.type = @school.name = scope
      @school
    elsif scope == 'help'
      school = School.find_or_create_by_name_and_domain_name('Help', 'help')
      school.type = scope
      school
    end
  end            

  def set_forum_activity_counts
    @counts = @discussable.forum_activities.inject({}) do |hash, elm|
      hash[elm.user_id] = elm.posts_count
    end
  end

  protected

    def set_discussable
      @discussable = find_or_initialize_discussable(params[:scope])
    end
end

