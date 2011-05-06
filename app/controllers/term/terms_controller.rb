class Term::TermsController < Term::TermController
  skip_filter :find_term

  def show
    @term = @school.terms.find((params[:id] || :last), :include => {:tracks => :marking_periods})
    @reported_grades, @tracks, @mp = @term.reported_grades_with_sort, @term.tracks, @term.marking_periods.last
    @other_term = @school.terms.detect{|t| t.id != @term.id}
  end

  def new
    redirect_to term_url(@school.terms.last) and return if @school.terms.count > 1
    @last_term = @school.terms.last
    @term = Term.new(:start => Date.today, :finish => Date.today + 30)
    @tracks = @last_term.tracks if @last_term
  end

  def create
    #TODO may be some problem with archive errors
    @last_term = @school.terms.last
    @tracks = params[:track]? Track.update(params[:track].keys,params[:track].values) : @last_term? @last_term.tracks : nil
    @term = @school.terms.create(params[:term])
    @term.tracks.each do |t|
      t.marking_periods.last.finish = params[:term][:finish]
      t.marking_periods.last.save unless @term.new_record?
    end
    if @term.valid? && (@tracks.nil? || @tracks.inject(true){|result, t| t.valid? && result})
      flash[:start], flash[:finish] = @term.start, @term.finish
      redirect_to term_path(@term), :notice => msg
    else
      render :action => "new"
    end
  end

  def edit
    @term = @school.terms.find(params[:id], :include => {:tracks => :marking_periods})
  end

  def update
    @term = @school.terms.find(params[:id], :include => {:tracks => :marking_periods})
    if @term.update_attributes(params[:term])
      redirect_to term_url(@term), :notice => msg
    else
      render :action => 'edit'
    end
  end

end

