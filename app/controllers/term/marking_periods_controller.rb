class Term::MarkingPeriodsController < Term::TermController

  def new
    @tracks = @term.tracks
    @tracks.each do |t|
      t.marking_periods.build(:start => t.finish + 1, :finish => t.finish + 30, :previous => t.finish)
    end
  end

  def create
    @tracks = @term.tracks
    @tracks.each_with_index do |t, i|
      dates = params[:marking_period][i.to_s]
      last = t.marking_periods.build(dates.merge(:reported_grade_id => 'temp', :previous => t.finish))
      last.valid? || @flag = last.errors
    end
    if @flag
      render :action => "new"
    else
      @marking_period = @term.reported_grades.create(:description => 'Marking Period', :allowed => true)
      @tracks.each_with_index do |t, i|
        dates = params[:marking_period][i.to_s]
        t.marking_periods(true).last.update_attributes(dates)
      end
      flash[:notice] = "<h2>Good News</h2>The marking period has been added."
      redirect_to term_url(@term)
    end
  end

  def destroy
    @marking_period = @school.reported_grades.find(params[:id])
    respond_to do |format|
      format.html do
        if params[:confirm].blank?
          render :action => "confirm_delete"
        else
          @marking_period.destroy
          flash[:notice] = "<h2>Good News</h2>The marking period has been removed."
          redirect_to term_path(@term)
        end
      end
      format.js do
        @marking_period.destroy
        flash[:notice] = "<h2>Good News</h2>The marking period has been removed."
        render :update do |page|
          page.redirect_to term_path(@term)
        end
      end
    end
  end

end

