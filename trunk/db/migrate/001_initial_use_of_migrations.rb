class InitialUseOfMigrations < ActiveRecord::Migration
  def self.up

  create_table "assignments", :force => true do |t|
    t.column "subject_id", :integer, :default => 0, :null => false
    t.column "title", :string, :limit => 100, :default => "", :null => false
    t.column "description", :text
    t.column "point_value", :string, :limit => 4
    t.column "date_assigned", :date
    t.column "date_due", :date
    t.column "category", :string, :limit => 20
  end

  add_index "assignments", ["subject_id"], :name => "fk_assignments_subject"

  create_table "breadcrumbs", :force => true do |t|
    t.column "name", :string, :limit => 25, :default => "", :null => false
    t.column "parent_id", :integer, :default => 0, :null => false
  end

  create_table "departments", :force => true do |t|
    t.column "name", :string, :limit => 30, :default => "", :null => false
    t.column "subject", :string, :limit => 100, :default => "", :null => false
  end

  create_table "events", :force => true do |t|
    t.column "name", :string, :limit => 60, :default => "", :null => false
    t.column "description", :string, :limit => 256, :default => "", :null => false
    t.column "date", :datetime, :null => false
  end

  create_table "grades", :force => true do |t|
    t.column "assignment_id", :integer, :default => 0, :null => false
    t.column "student_id", :integer, :default => 0, :null => false
    t.column "score", :string, :limit => 3
    t.column "date_submitted", :date
  end

  add_index "grades", ["student_id"], :name => "fk_grades_student"
  add_index "grades", ["assignment_id"], :name => "fk_grades_assignment"

  create_table "map_points", :force => true do |t|
    t.column "lat", :float, :limit => 8, :default => 0.0, :null => false
    t.column "lon", :float, :limit => 8, :default => 0.0, :null => false
    t.column "kind_of", :string, :limit => 10
  end

  create_table "pages", :force => true do |t|
    t.column "controller", :string, :limit => 20, :default => "", :null => false
    t.column "action", :string, :limit => 20, :default => "", :null => false
    t.column "title", :string, :limit => 40
  end

  create_table "people", :force => true do |t|
    t.column "type", :string, :limit => 20, :default => "", :null => false
    t.column "school_id", :integer, :default => 0, :null => false
    t.column "id_number", :integer
    t.column "first_name", :string, :limit => 25
    t.column "middle_name", :string, :limit => 25
    t.column "last_name", :string, :limit => 25
    t.column "login", :string, :limit => 20
    t.column "password", :string, :limit => 20
    t.column "birth_date", :date
    t.column "home_language", :string, :limit => 20
    t.column "title", :string, :limit => 3
    t.column "position", :string, :limit => 25
    t.column "year", :integer, :limit => 4
    t.column "email", :string, :limit => 50
    t.column "grade", :string, :limit => 2
    t.column "parent_of", :integer
  end

  add_index "people", ["school_id"], :name => "fk_schools_person"
  add_index "people", ["parent_of"], :name => "fk_parent_of"

  create_table "phone_numbers", :force => true do |t|
    t.column "person_id", :integer, :default => 0, :null => false
    t.column "phone_number", :integer, :default => 0, :null => false
    t.column "kind_of", :string, :limit => 6, :default => "", :null => false
  end

  add_index "phone_numbers", ["person_id"], :name => "fk_numbers_person"

  create_table "schools", :force => true do |t|
    t.column "name", :string, :limit => 100
    t.column "street", :string
    t.column "city", :string, :limit => 60
    t.column "state", :string, :limit => 2
    t.column "zip", :string, :limit => 9
    t.column "phone", :integer
  end

  create_table "sidebars", :force => true do |t|
    t.column "title", :string, :limit => 100, :default => "", :null => false
    t.column "description", :text, :default => "", :null => false
    t.column "url", :string, :limit => 100, :default => "", :null => false
  end

  create_table "students_subjects", :id => false, :force => true do |t|
    t.column "student_id", :integer, :default => 0, :null => false
    t.column "subject_id", :integer, :default => 0, :null => false
  end

  add_index "students_subjects", ["subject_id"], :name => "fk_ps_subject"

  create_table "subjects", :force => true do |t|
    t.column "teacher_id", :integer, :default => 0, :null => false
    t.column "name", :string, :limit => 100, :default => "", :null => false
    t.column "location", :string, :limit => 50
    t.column "credit", :float, :limit => 4
    t.column "time", :time
    t.column "department", :string, :limit => 20
  end

  add_index "subjects", ["teacher_id"], :name => "fk_subjects_teacher"

  add_foreign_key_constraint "assignments", "subject_id", "subjects", "id", :name => "fk_assignments_subject", :on_update => nil, :on_delete => nil

  add_foreign_key_constraint "grades", "assignment_id", "assignments", "id", :name => "fk_grades_assignment", :on_update => nil, :on_delete => nil
  add_foreign_key_constraint "grades", "student_id", "people", "id", :name => "fk_grades_student", :on_update => nil, :on_delete => nil

  add_foreign_key_constraint "people", "parent_of", "people", "id", :name => "fk_parent_of", :on_update => nil, :on_delete => nil
  add_foreign_key_constraint "people", "school_id", "schools", "id", :name => "fk_schools_person", :on_update => nil, :on_delete => nil

  add_foreign_key_constraint "phone_numbers", "person_id", "people", "id", :name => "fk_numbers_person", :on_update => nil, :on_delete => nil

  add_foreign_key_constraint "students_subjects", "student_id", "people", "id", :name => "fk_ps_student", :on_update => nil, :on_delete => nil
  add_foreign_key_constraint "students_subjects", "subject_id", "subjects", "id", :name => "fk_ps_subject", :on_update => nil, :on_delete => nil

  add_foreign_key_constraint "subjects", "teacher_id", "people", "id", :name => "fk_subjects_teacher", :on_update => nil, :on_delete => nil
  
  end

  def self.down
  end
end
