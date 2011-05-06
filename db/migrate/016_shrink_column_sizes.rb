class ShrinkColumnSizes < ActiveRecord::Migration
  def self.up
    change_column :addresses, :id, :integer, :limit => 6
    change_column :addresses, :addressable_id, :integer, :limit => 9
    change_column :addresses, :addressable_type, :string, :limit => 10

    change_column :assignments, :id, :integer, :limit => 7
    change_column :assignments, :section_id, :integer, :limit => 5
    change_column :assignments, :marking_period, :integer, :limit => 1

    change_column :departments, :id, :integer, :limit => 4
    change_column :departments, :school_id, :integer, :limit => 3

    drop_table :engine_schema_info
    
    change_column :grades, :id, :integer, :limit => 9
    change_column :grades, :assignment_id, :integer, :limit => 7
    change_column :grades, :student_id, :integer, :limit => 9

    drop_table :marking_period_grades

    change_column :marking_periods, :id, :integer, :limit => 4
    change_column :marking_periods, :school_id, :integer, :limit => 3

    change_column :milestones, :id, :integer, :limit => 8
    change_column :milestones, :student_id, :integer, :limit => 9
    change_column :milestones, :section_id, :integer, :limit => 5

    change_column :roles, :id, :integer, :limit => 3
    change_column :roles, :title, :string, :limit => 20

    change_column :roles_users, :role_id, :integer, :limit => 3
    change_column :roles_users, :user_id, :integer, :limit => 9

    change_column :rollbook_entries, :id, :integer, :limit => 7
    change_column :rollbook_entries, :student_id, :integer, :limit => 9
    change_column :rollbook_entries, :section_id, :integer, :limit => 5
    change_column :rollbook_entries, :position, :integer, :limit => 3

    change_column :schools, :id, :integer, :limit => 3
    change_column :schools, :low_grade, :integer, :limit => 2
    change_column :schools, :high_grade, :integer, :limit => 2
    change_column :schools, :low_period, :integer, :limit => 1
    change_column :schools, :high_period, :integer, :limit => 2

    change_column :sections, :id, :integer, :limit => 5
    change_column :sections, :teacher_id, :integer, :limit => 9
    change_column :sections, :department_id, :integer, :limit => 4
    change_column :sections, :subject_id, :integer, :limit => 4

    change_column :sessions, :id, :integer, :limit => 7
    change_column :sessions, :session_id, :string, :limit => 32

    change_column :subjects, :id, :integer, :limit => 4
    change_column :subjects, :department_id, :integer, :limit => 4

    change_column :users, :id, :integer, :limit => 9
    change_column :users, :school_id, :integer, :limit => 3
    change_column :users, :id_number, :integer, :limit => 9
    change_column :users, :parent_of, :integer, :limit => 9
  end

  def self.down
    change_column :addresses, :id, :integer, :limit => 11
    change_column :addresses, :addressable_id, :integer, :limit => 11
    change_column :addresses, :addressable_type, :string

    change_column :assignments, :id, :integer, :limit => 11
    change_column :assignments, :section_id, :integer, :limit => 11
    change_column :assignments, :marking_period, :integer, :limit => 11

    change_column :departments, :id, :integer, :limit => 11
    change_column :departments, :school_id, :integer, :limit => 11

    create_table :engine_schema_info do |t|
      t.column :engine_name, :string
      t.column :version, :integer
    end
    
    change_column :grades, :id, :integer, :limit => 11
    change_column :grades, :assignment_id, :integer, :limit => 11
    change_column :grades, :student_id, :integer, :limit => 11

    create_table :marking_period_grades do |t|
      t.column :student_id, :integer
      t.column :section_id, :integer
      t.column :marking_period, :integer
      t.column :points_earned, :integer
      t.column :points_possible, :integer
    end

    change_column :marking_periods, :id, :integer, :limit => 11
    change_column :marking_periods, :school_id, :integer, :limit => 11

    change_column :milestones, :id, :integer, :limit => 11
    change_column :milestones, :student_id, :integer, :limit => 11
    change_column :milestones, :section_id, :integer, :limit => 11

    change_column :roles, :id, :integer, :limit => 11
    change_column :roles, :title, :limit => 255

    change_column :roles_users, :role_id, :integer, :limit => 11
    change_column :roles_users, :user_id, :integer, :limit => 11

    change_column :rollbook_entries, :id, :integer, :limit => 11
    change_column :rollbook_entries, :student_id, :integer, :limit => 11
    change_column :rollbook_entries, :section_id, :integer, :limit => 11
    change_column :rollbook_entries, :position, :integer, :limit => 11

    change_column :schools, :id, :integer, :limit => 11
    change_column :schools, :low_grade, :string, :limit => 2
    change_column :schools, :high_grade, :string, :limit => 2
    change_column :schools, :low_period, :integer, :limit => 11
    change_column :schools, :high_period, :integer, :limit => 11

    change_column :sections, :id, :integer, :limit => 11
    change_column :sections, :teacher_id, :integer, :limit => 11
    change_column :sections, :department_id, :integer, :limit => 11
    change_column :sections, :subject_id, :integer, :limit => 11

    change_column :sessions, :id, :integer, :limit => 11
    change_column :sessions, :session_id, :string, :limit => 255

    change_column :subjects, :id, :integer, :limit => 11
    change_column :subjects, :department_id, :integer, :limit => 11

    change_column :users, :id, :integer, :limit => 11
    change_column :users, :school_id, :integer, :limit => 11
    change_column :users, :id_number, :integer, :limit => 11
    change_column :users, :parent_of, :integer, :limit => 11
  end
end
