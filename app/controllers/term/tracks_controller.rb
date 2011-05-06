class Term::TracksController < Term::TermController

  def create
    @track = @term.tracks.build(params[:track])
    if @track.save
      flash[:notice] = "<h2>Good News</h2>Track #{@track.position} added"
      redirect_to term_url(@term)
    else
      render :action => "new"
    end
  end

  def new
    @track = @term.tracks.build()
    @term.marking_periods.each{|mp| @track.marking_periods.build}
  end

  def destroy
    @track = @term.tracks.find(params[:id])
    if @track.occupied?
      flash[:error] = "The track cannot be destroyed if it contains any sections in which students are enrolled."
    else
      flash[:notice] = "<h2>Good News</h2>The track has been deleted."
      @track.destroy
    end
    respond_to do |format|
      format.html{redirect_to term_url(@term)}
      format.js{render :update do |page|
          page.redirect_to term_url(@term)
      end}
    end
  end

  def edit
    @track = @term.tracks.find(params[:id], :include => :marking_periods)
    @marking_periods = @track.marking_periods
  end

  def update
    @track = @term.tracks.find(params[:id])
    if @track.update_attributes(params[:track])
      flash[:notice] = "<h2>Good News</h2>Marking period dates updated"
      redirect_to term_url(@term)
    else
      render :action => "edit" and return
    end
  end
end

