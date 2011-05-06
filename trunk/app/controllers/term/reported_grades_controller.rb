class Term::ReportedGradesController < Term::TermController

  def index
    set_grade_lists
    @grade, @editgrade = flash[:grade], flash[:editgrade] #kinda ugly hack, transfers grade with errors from 'create', rather than rendering index from create (and exposing action name)
  end

  def create
    @grade = @term.reported_grades.build(params[:grade])
    if @grade.save
      respond_to do |format|
        format.html{
          flash[:notice] = "<h2>Good News</h2>#{@grade.description} added";redirect_to term_reported_grades_url(@term)}
        format.js{set_grade_lists}
      end
    else
      flash[:grade] = @grade
      respond_to do |format|
        format.html{redirect_to term_reported_grades_url(@term)} #TODO: Do I want this to redirect, or is there a new template?
        format.js{@replace = 'grade';render :action => 'fail'}
      end
    end
  end

  def edit
    @rpg = @term.reported_grades.find(params[:id])
  end

  def update
    @grade = @term.reported_grades.find(params[:id])
    if @grade.update_attributes(params[:rg])
      respond_to do |format|
        format.html do
          flash[:notice] = "<h2>Good News</h2>Update Successful"
          redirect_to term_reported_grades_url(@term)
        end
        format.js{set_grade_lists}
      end
    else
      respond_to do |format|
        flash[:editgrade] = @grade
        format.html{redirect_to term_reported_grades_url(@term)}
        format.js{@replace = 'editgrade';render :action => 'fail'}
      end
    end
  end

  def destroy
    @reported_grades = @term.reported_grades_with_sort
    @grade = @reported_grades.detect{|g| g.id == params[:id].to_i}
    if @grade.destroy
      respond_to do |format|
        format.html{flash[:notice] = "<h2>Good News</h2>#{@grade.description} removed"; redirect_to term_reported_grades_path(@term)}
        format.js{@reported_grades.delete(@grade)}
      end
    else
      assign = @grade.description =~ /Marking Period/? ', and make sure every assignment teachers have created belong to a marking period other than this one.' : '.'
      msg = "Some teachers have entered student grades for #{@grade.description}. To ensure no data is lost, you must make sure they have set all student grades for this grade to zero" + assign
      if request.xhr?
        render :update do |page|
          page.insert_html :after, 'destroy_error_insertion', msg
        end
      else
        flash[:error] = msg
        redirect_to term_reported_grades_url(@term)
      end
    end
  end

private

  def set_grade_lists
    placeholder = ReportedGrade.new(:description => 'Insert first');placeholder.id=0
    @reported_grades = @term.reported_grades_with_sort
    @insertables = @reported_grades.dup.unshift(placeholder)
  end
end

