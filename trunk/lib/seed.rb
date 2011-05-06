class Seed

  def initialize(start_date, end_date, mp)
    @school = School.find_by_domain_name('newschool', :include => :teachers)
    @school ||= School.find_by_domain_name('modelschool', :include => :teachers)
    mp = @school.terms[0].reported_grades.find_by_description("Marking Period #{mp}")
    @rpg = mp.id
    @start_date = start_date
    @end_date = end_date
    @today = Date.today
  end
  #what this needs is a way to autocalc the most recent assignment, and start based on that. better to do every day, if I could figure out how to do that.
  def catchup(from, to)
    @school.teachers.find(:all, :include => :sections).each do |teacher|
      teacher.sections.each do |section|
        s = Section.find_by_id(section.id, :include => [{:assignments => :grades}, :subject, {:rollbook_entries => :milestones}], :conditions => ['assignments.date_due BETWEEN (?) AND (?)', from, to])
        next unless s
        puts "starting catchup for section #{s.id}"
        s.assignments.each do |assignment| 
          puts "assignment #{assignment.position}"
          if assignment.grades.any?{|g| g.score != '-'}
            puts "already graded"
          else
            create_scores_for(assignment, s)
          end
        end
      end
    end
  end

  def generate_data
    @sections = Section.find(:all, :include => [:rollbook_entries, :subject], :conditions => ['teacher_id IN (?)', @school.teachers.collect(&:id)])
    @start_date.upto(@end_date) do |day|
      @sections.each do |section|
        puts "generating data for section #{section.id}"
        scheduled = SCHEDULE[section.name.downcase.gsub(/\s/, '_').to_sym][day.wday]
        next unless scheduled
        scheduled.each do |type_or_frequency|
          puts "generating assignment"
          generate_assignment_for(section, type_or_frequency, day)
        end
      end
    end
  end

  def generate_assignment_for(section, type_or_frequency, day)
    if type_or_frequency.is_a?(Symbol)
      type = type_or_frequency
      return if (type == :classwork && rand > 0.8) || (type == :homework && rand > 0.9)
      point_value = POINTS[type].rand
      assignment = section.assignments.create(:point_value => point_value, :date_assigned => day, :date_due => day + due_date_lag(type.to_s, day, section), :reported_grade_id => @rpg, :category => type.to_s, :title => type.to_s.capitalize)
      create_scores_for(assignment, section) unless assignment.date_due > @today
    elsif (day - @start_date).to_i / 7 == type_or_frequency.values[0]
      generate_assignment_for(section, type_or_frequency.keys[0], day)
    end
  end

  def create_scores_for(assignment, section)
    value = assignment.point_value
    if SCORES[section.name.downcase.gsub(/\s/, '_').to_sym] && scores = SCORES[section.name.downcase.gsub(/\s/, '_').to_sym][assignment.category.to_sym]
      assignment.grades.each{|g| g.update_attribute('score', scores.rand * value)}
    else
      assignment.grades.each{|g| g.update_attribute('score', [0, 0.5, 0.7, 0.8, 0.9, 1, 1].rand * value)}
    end
  end

  def due_date_lag(category, date, section)
    case category
    when 'classwork', 'participation'
      0
    when 'homework'
      date.wday == 5 ? 3 : 1
    when 'report', 'project'
      11
    when 'poem', 'performance'
      4
    when 'quiz'
      LAG[:quiz][section.name.downcase.gsub(/\s/, '_').to_sym] || 2
    when 'test', 'essay'
      LAG[:test][section.name.downcase.gsub(/\s/, '_').to_sym] || 4
    when 'lab'
      LAG[:lab][section.name.downcase.gsub(/\s/, '_').to_sym] || 2
    end
  end

  def prune(offset)
    date = Date.today - offset
    assignments = Assignment.find_all_by_date_due(date)
    assignments.group_by(&:section_id).each do |g|
      group = g.last
      until group.empty? do
        assignment = group.pop
        assignment.destroy if group.any?{|a| a.category == assignment.category && a.id != assignment.id}
      end
    end
  end
  
  CLASSWORK = [0, 0, 0.5, 0.5, 1, 1, 1, 1, 1, 1]
  CLASSWORK_2 = [0, 0.5, 0.5, 0.7, 1, 1, 1, 1, 1, 1]
  HOMEWORK_1 = [0, 0, 0, 0.5, 0.5, 0.5, 1, 1, 1, 1]
  HOMEWORK_2 = [0, 0.9, 1, 1, 1, 1, 1, 1, 1, 1]
  HOMEWORK_3 = [0, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 1, 1]
  HOMEWORK_4 = [0, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 0.9, 1, 1]
  LAB = [0.5, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 0.9, 1, 1]
  QUIZ = [0, 0.3, 0.5, 0.6, 0.6, 0.7, 0.8, 0.9, 1, 1]
  QUIZ_2 = [0.5, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1, 1]
  QUIZ_3 = [0.5, 0.6, 0.7, 0.8, 0.8, 0.9, 0.9, 0.9, 1, 1]
  TEST_1 = [0, 0.3 ,0.5, 0.5, 0.6, 0.6, 0.7, 0.8, 0.9, 1]
  TEST_2 = [0, 0.3, 0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.9, 1]
  TEST_3 = [0, 0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 1]
  TEST_4 = [0.5, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 0.9, 0.95, 1]
  WRITING = [0, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1]
  WRITING_2 = [0.7, 0.7, 0.8, 0.8, 0.8, 0.9, 0.9, 0.92, 0.94, 1]

  SCORES = {:basic_math => {:classwork => CLASSWORK, :homework => HOMEWORK_1, :quiz => QUIZ, :test => TEST_1},
  :algebra_i => {:classwork => CLASSWORK, :homework => HOMEWORK_1, :quiz => QUIZ, :test => TEST_2}, :geometry => {:classwork => CLASSWORK, :homework => CLASSWORK, :quiz => QUIZ_2, :test => TEST_3},
  :precalculus => {:homework => HOMEWORK_2, :quiz => QUIZ_3, :test => TEST_4},
  :statistics => {:homework => HOMEWORK_2, :quiz => QUIZ_3, :test => TEST_4},
  :calculus => {:homework => HOMEWORK_2, :quiz => QUIZ_3, :test => TEST_4},
  :reading => {:classwork => CLASSWORK, :quiz => QUIZ, :test => TEST_1},
  :english_9 => {:classwork => CLASSWORK, :homework => HOMEWORK_3, :quiz => QUIZ_3, :test => TEST_2},
  :english_10 => {:classwork => CLASSWORK, :homework => HOMEWORK_3, :quiz => QUIZ_3, :test => TEST_3, :essay => WRITING, :report => WRITING},
  :communication => {:classwork => CLASSWORK, :speech => WRITING},
  :world_literature => {:homework => HOMEWORK_2, :test => TEST_3, :essay => WRITING, :report => WRITING},
  :poetry => {:poem => HOMEWORK_2},
  :drama => {:classwork => HOMEWORK_2, :performance => [0.8, 0.8, 0.8, 0.85, 0.85, 0,9, 0.9, 0.95, 1, 1]},
  :ap_english => {:participation => [0.7, 0.9, 1, 1, 1, 1, 1, 1, 1, 1], :essay => WRITING_2},
  :journalism => {:classwork => CLASSWORK, :report => WRITING_2},
  :civics => {:classwork => HOMEWORK_2, :homework => HOMEWORK_3, :quiz => QUIZ_3, :test => TEST_4, :report => HOMEWORK_3},
  :social_studies => {:classwork => CLASSWORK, :quiz => QUIZ, :test => TEST_2, :project => HOMEWORK_3},
  :world_history => {:classwork => CLASSWORK, :homework => HOMEWORK_4, :quiz => QUIZ_3, :test => TEST_4, :report => HOMEWORK_3},
  :american_history => {:classwork => CLASSWORK, :homework => HOMEWORK_4, :quiz => QUIZ_3, :test => TEST_4, :report => HOMEWORK_3},
  :economics => {:homework => HOMEWORK_4, :quiz => QUIZ_3, :test => TEST_4, :project => HOMEWORK_3},
  :psychology => {:homework => HOMEWORK_4, :quiz => QUIZ_3, :test => TEST_4, :project => HOMEWORK_3},
  :ap_european_history => {:test => TEST_4, :essay => HOMEWORK_3, :report => HOMEWORK_3},
  :ap_government => {:test => TEST_4, :essay => HOMEWORK_3, :report => HOMEWORK_3},
  :sociology => {:classwork => CLASSWORK, :quiz => QUIZ_3, :project => HOMEWORK_3},
  :general_science => {:classwork => CLASSWORK, :quiz => QUIZ, :test => TEST_3, :lab => QUIZ_3},
  :chemistry_i => {:homework => HOMEWORK_4, :quiz => QUIZ_3, :test => TEST_4, :lab => LAB},
  :chemistry_ii => {:homework => HOMEWORK_4, :test => TEST_4, :lab => LAB},
  :biology_i => {:classwork => CLASSWORK, :test => TEST_4, :lab => LAB},
  :biology_ii => {:test => TEST_4, :lab => LAB},
  :physics_i => {:homework => HOMEWORK_4, :test => TEST_4, :lab => LAB},
  :physics_ii => {:test => TEST_4, :lab => LAB, :report => TEST_4},
  :environmental_science => {:homework => HOMEWORK_4, :test => TEST_4},
  :spanish_i => {:classwork => CLASSWORK_2, :homework => CLASSWORK_2, :quiz => QUIZ, :test => TEST_4},
  :spanish_ii => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4, :quiz => QUIZ, :test => TEST_4},
  :spanish_iii => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4, :quiz => QUIZ, :test => TEST_4},
  :spanish_iv => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4, :test => TEST_4},
  :german_i => {:classwork => CLASSWORK_2, :homework => CLASSWORK_2, :quiz => QUIZ, :test => TEST_4},
  :german_ii => {:classwork => CLASSWORK_2, :homework => CLASSWORK_2, :quiz => QUIZ, :test => TEST_4},
  :german_iii => {:classwork => CLASSWORK_2, :homework => CLASSWORK_2,  :test => TEST_4},
  :chorus => {:participation => CLASSWORK_2}, :band => {:participation => CLASSWORK_2}, :physical_education => {:participation => CLASSWORK_2}, :computer_literacy => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4}, :ruby => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4, :project => LAB}, :web_design => {:classwork => CLASSWORK_2, :homework => HOMEWORK_4, :project => LAB}}

  POINTS = {:classwork => [5, 10], :homework => [5, 10, 20], :quiz => [10, 20, 25, 50], :test => [50, 60, 100], :poem => [25], :essay => [25, 50, 100], :report => [50, 100], :lab => [20, 25, 30], :project => [100], :performance => [5], :speech => [50], :participation => [5, 10]}

  SCHEDULE = {:basic_math => {1 => [:classwork, :quiz, {:test => 2}], 2 => [:classwork], 3 => [:classwork], 4 => [:classwork], 5 => [:classwork]},
  :algebra_i => {1 => [:homework, :quiz, :test], 2 => [:homework], 3 => [:homework, :quiz], 5 => [:classwork, :homework]},
  :american_history => {1 => [{:report => 4}, :quiz, {:test => 2}], 2 => [:homework], 3 => [:classwork], 4 => [:homework], 5 => [:classwork]},
  :ap_english => {1 => [:participation, {:essay => 3}], 2 => [:participation], 3 => [:participation], 4 => [:participation], 5 => [:participation]},
  :ap_european_history => {1 => [:essay, {:report => 4}, {:test => 2}]},
  :ap_government => {1 => [:essay, {:report => 4}, {:test => 2}]},
  :band => {1 => [:participation], 2 => [:participation], 3 => [:participation], 4 => [:participation], 5 => [:participation]},
  :biology_i => {1 => [:lab, {:test => 2}]},
  :biology_ii => {1 => [:lab, {:test => 2}]},
  :calculus => {1 => [:homework, :quiz, {:test => 3}], 2 => [:homework], 3 => [:homework], 4 => [:homework], 5 => [:homework]},
  :chemistry_i => {1 => [:lab, {:test => 3}], 4 => [:homework], 5 => [:homework]},
  :chemistry_ii => {1 => [:lab, {:test => 2}]},
  :civics => {1 => [:classwork, :quiz, {:test => 2}, {:report => 4}], 2 => [:classwork, :homework], 4 => [:classwork], 5 => [:classwork]},
  :communication => {1 => [:classwork], 3 => [:classwork], 5 => [:classwork]},
  :computer_literacy => {1 => [:classwork], 2 => [:classwork], 3 => [:classwork, :quiz], 4 => [:classwork], 5 => [:classwork]},
  :drama => {1 => [:performance]},
  :economics => {1 => [{:project => 4}, :quiz, {:test => 2}], 2 => [:homework], 3 => [:classwork], 4 => [:homework], 5 => [:classwork]},
  :english_9 => {1 => [:classwork, :quiz, :homework, {:test => 2}], 3 => [:classwork, :homework], 5 => [:classwork]},
  :english_10 => {1 => [{:test => 2}, {:essay => 3}], 2 => [:classwork], 3 => [:classwork], 5 => [:homework]},
  :environmental_science => {1 => [{:test => 2}], 2 => [:homework], 4 => [:homework], 5 => [:homework]},
  :general_science => {1 => [:lab, {:quiz => 2}, {:test => 3}]},
  :geometry => {1 => [:homework, :quiz, :test], 3 => [:classwork], 4 => [:classwork], 5 => [:homework]},
  :journalism => {1 => [:classwork, :report], 2 => [:classwork], 3 => [:classwork], 4 => [:classwork], 5 => [:classwork]},
  :physical_education => {1 => [:participation], 2 => [:participation], 3 => [:participation], 4 => [:participation], 5 => [:participation]},
  :physics_i => {1 => [:lab, {:test => 2}], 4 => [:homework]},
  :physics_ii => {1 => [:lab, {:test => 2}, {:report => 8}]},
  :poetry => {1 => [:poem]},
  :precalculus => {1 => [:homework, {:test => 2}], 2 => [:homework], 3 => [:homework], 4 => [:homework], 5 => [:homework]},
  :psychology => {1 => [{:project => 4}, :quiz, {:test => 2}], 2 => [:homework], 3 => [:classwork], 4 => [:homework], 5 => [:classwork]},
  :reading => {1 => [:classwork, :quiz, {:test => 2}], 2 => [:classwork], 3 => [:classwork], 4 => [:classwork], 5 => [:classwork]},
  :ruby => {1 => [:classwork, :test], 2 => [:classwork], 3 => [{:project => 2}], 4 => [:classwork], 5 => [:classwork]},
  :social_studies => {1 => [:classwork, :quiz, {:test => 2}, {:project => 4}], 2 => [:classwork], 3 => [:classwork], 4 => [:classwork], 5 => [:classwork]},
  :sociology => {1 => [:classwork, :quiz], 3 => [:classwork], 4 => [:classwork]},
  :spanish_i => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :spanish_ii => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :spanish_iii => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :spanish_iv => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :german_i => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :german_ii => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :german_iii => {1 => [:classwork, :homework, :quiz, {:test => 2}], 3 => [:classwork, :homework]}, :chorus => {1 => [:participation], 2 => [:participation], 3 => [:participation], 4 => [:participation], 5 => [:participation]},
  :statistics => {1 => [:homework, {:test => 3}], 2 => [:homework], 3 => [:homework], 4 => [:homework], 5 => [:homework]},
  :web_design => {1 => [:classwork, :test], 2 => [:classwork], 3 => [{:project => 2}], 4 => [:classwork], 5 => [:classwork]},
  :world_history => {1 => [{:report => 4}, :quiz, {:test => 2}], 2 => [:homework], 3 => [:classwork], 4 => [:homework], 5 => [:classwork]},
  :world_literature => {1 => [{:essay => 2}, {:test => 3}, :homework], 3 => [:homework]}}

  LAG = {:quiz => {:precalculus => 4, :calculus => 1, :reading => 1, :english_10 => 3, :civics => 3, :world_history => 3, :economics => 3, :american_history => 3, :psychology => 3, :sociology => 1, :general_science => 3, :spanish_i => 3, :spanish_iv => 3, :spanish_ii => 3, :spanish_iii => 3, :german_i => 3, :german_ii => 3, :german_iii => 3}, :test => {:precalculus => 3, :reading => 3, :english_10 => 3,  :chemistry_ii => 7, :biology_i => 7}, :essay => {:ap_english => 9, :world_literature => 9, :ap_government => 2, :ap_european_history => 2, :english_10 => 11}, :lab => {:general_science => 1, :chemistry_i => 1, :biology_ii => 3}}
end

