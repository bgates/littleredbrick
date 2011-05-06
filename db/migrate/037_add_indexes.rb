class AddIndexes < ActiveRecord::Migration
  def self.up

    change_column :posts, :discussable_type, :string, :limit => 10
    change_column :forums, :discussable_type, :string, :limit => 10
    change_column :reported_grades, :reportable_type, :string, :limit => 10
#=begin all these were added by hand to the production db, so this was only used in dev; commented out for that, unsatisfactory reason
    add_index :assignments, :reported_grade_id

    add_index :departments, :school_id

    add_index :events, [:invitable_type, :invitable_id, :date]#is that the best? check how I'm searching, and how indexes work
    add_index :events, :creator_id

    add_index :forums, [:discussable_type, :discussable_id]
    add_index :forums, :owner_id

    add_index :logins, :user_id

    add_index :marking_periods, :reported_grade_id
    add_index :marking_periods, :track_id

    add_index :milestones, :rollbook_entry_id
    add_index :milestones, :reported_grade_id

    add_index :monitorships, :user_id
    add_index :monitorships, :topic_id

    add_index :parents_students, :parent_id
    add_index :parents_students, :student_id

    add_index :posts, [:discussable_type, :discussable_id]

    add_index :reported_grades, [:reportable_type, :reportable_id]

    add_index :terms, :school_id

    add_index :topics, :user_id

    add_index :tracks, :term_id
#=end
    #remove_index :users, :name => 'fk_schools_person'
    add_index :users, [:school_id, :type]
    add_index :roles, :title
    remove_index :sections, :teacher_id
    add_index :sections, [:teacher_id, :current]
    #end
  end

  def self.down
    remove_index :assignments, :reported_grade_id

    remove_index :departments, :school_id

    remove_index :events, [:invitable_type, :invitable_id, :date]#is that the best? check how I'm searching, and how indexes work
    remove_index :events, :creator_id

    remove_index :forums, [:discussable_type, :discussable_id]
    remove_index :forums, :owner_id

    remove_index :logins, :user_id

    remove_index :marking_periods, :reported_grade_id
    remove_index :marking_periods, :track_id

    remove_index :milestones, :rollbook_entry_id
    remove_index :milestones, :reported_grade_id

    remove_index :monitorships, :user_id
    remove_index :monitorships, :topic_id

    remove_index :parents_students, :parent_id
    remove_index :parents_students, :student_id

    remove_index :posts, [:discussable_type, :discussable_id]

    remove_index :reported_grades, [:reportable_type, :reportable_id]

    remove_index :terms, :school_id

    remove_index :topics, :user_id

    remove_index :tracks, :term_id

    remove_index :users, [:school_id, :type]
    #add_index :users, :school_id
  end
end
