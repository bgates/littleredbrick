class Beast::ModeratorsController < BeastController

  def destroy
    @moderatorship = @forum.moderatorships.find(params[:id], :include => :user)
    if @moderatorship.may_not_be_destroyed_for?(@forum)
      flash[:error] = msg(:error)
    elsif @moderatorship.destroy
      flash[:notice] = msg
    end
    @user = @moderatorship.user
    respond_to do |format|
      format.html{redirect_to path}
      format.js do
        path = path
        render :update do |page|
          page.redirect_to path
        end
      end
    end
  end

  def index
    @moderators = @forum.moderators
  end

  def create
    respond_to do |format|
      format.html do
        @user = @forum.members.find(params[:user][:id])
        create_multiple if @user
        redirect_to path, :notice => msg
      end
      format.js do
        @user = @forum.members.find(params[:id])
        if @user
          @user.moderatorships.create(:forum_id => params[:forum_id])
          flash[:notice] = msg
        end
        path = path 
        render :update do |page|
          page.redirect_to path
        end
      end
    end
  end

  def update
    @forum.moderatorships.update_list(params[:moderator].keys.map(&:to_i))
    redirect_to forum_moderators_path(@discussable, @forum), :notice => msg
  end

  def search
    @potential_moderators = Moderatorship.search(params[:search].downcase, :school_id => @school.id, :discussable => @discussable)
    respond_to do |wants|
      wants.html do
        if @potential_moderators.empty?
          redirect_to forum_moderators_path(@discussable, @forum),
                      :flash => { :error => msg(:error) }
        elsif @potential_moderators.length == 1
          @user = @forum.members.find(@potential_moderators.first.id)
          @user.moderatorships.create(:forum_id => @forum)
          redirect_to forum_moderators_path(@discussable, @forum), 
                      :notice => msg
        else
          @moderator = Moderatorship.new
          render :action => 'new' #TODO: build out this template
        end
      end
      wants.js{render :action => 'search_results', :layout => false}
    end
  end
protected
  def authorized?
    @forum = @discussable.forums.find(params[:forum_id])
    @forum.owner_id == current_user.id
  end

  def create_multiple
    params[:forum].each{|k,v| @user.moderatorships.create(:forum_id => k)}
  end

  #this is ugly. Creating a moderatorship from the moderators page involves submitting an autocompleter, which doesn't have extra params (or at least I don't want to throw them in, since the search autocompleter is used in other places). It can't take a param[:return] as a flag. Likewise, the *delete* from the reader page is ajax (button-to), so it can't take a hidden field either. OK, I could rewrite the button-to into a form and throw in a hidden field, but f it. The places I can include the hidden field are create from moderators/index and destroy from readers/show. That means the @path, which should redirect back (wouldn't it be nice if redirect back just worked?), depends on both the presence of the tag and on the method being called.
  def path
    switch ? forum_moderators_path(@discussable, @forum) : reader_path(@discussable, @user)
  end

  def switch
    params[:return].blank? ^ (action_name == 'destroy')
  end
end

