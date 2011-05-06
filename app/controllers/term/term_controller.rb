class Term::TermController < ApplicationController
  before_filter :login_required, :find_term
  layout :initial_or_by_user

  protected

    def find_term
      @term = @school.terms.find(params[:term_id])
    end

end

