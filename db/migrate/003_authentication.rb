class Authentication < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'    

    rename_table "people", "users"
    change_column :users, :login,            :string, :limit => 40
    change_column :users, :email,            :string, :limit => 100
    add_column :users, :crypted_password,    :string, :limit => 40
    add_column :users, :salt,                :string, :limit => 40
    add_column :users, :created_at,          :datetime
    add_column :users, :updated_at,          :datetime
    add_column :users, :activation_code,     :string, :limit => 40
    add_column :users, :activated_at,        :datetime
    add_column :users, :password_reset_code, :string, :limit => 40
      
    remove_column :users, :password
    create_table "roles", :force => true do |t|
      t.column :title, :string
    end
    create_table "roles_users", :id => false, :force => true do |t|
      t.column :role_id, :integer
      t.column :user_id, :integer
    end  
    add_index "roles_users", ["role_id"], :name => "fk_ru_role"
    add_index "roles_users", ["user_id"], :name => "fk_ru_user"
    add_foreign_key_constraint "roles_users", "role_id", "roles", "id", :name => "fk_ru_role", :on_update => nil, :on_delete => nil
    add_foreign_key_constraint "roles_users", "user_id", "users", "id", :name => "fk_ru_user", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "grades", "fk_grades_student"
    add_foreign_key_constraint "grades", "student_id", "users", "id", :name => "fk_grades_student", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "phone_numbers", "fk_numbers_person"
    remove_index :phone_numbers, :name => :fk_numbers_person
    rename_column :phone_numbers, :person_id, :user_id
    add_index "phone_numbers", ["user_id"], :name => "fk_numbers_person"
    add_foreign_key_constraint "phone_numbers", "user_id", "users", "id", :name => "fk_numbers_person", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "students_subjects", "fk_ps_student"
    remove_foreign_key_constraint "students_subjects", "fk_ps_subject"
    remove_index :students_subjects, :name => :fk_ps_student
    add_index "students_subjects", ["student_id"], :name => "fk_ss_student"
    remove_index :students_subjects, :name => :fk_ps_subject
    add_index "students_subjects", ["subject_id"], :name => "fk_ss_subject"    
    add_foreign_key_constraint "students_subjects", "student_id", "users", "id", :name => "fk_ss_student", :on_update => nil, :on_delete => nil
    add_foreign_key_constraint "students_subjects", "subject_id", "subjects", "id", :name => "fk_ss_subject", :on_update => nil, :on_delete => nil

    remove_foreign_key_constraint "subjects", "fk_subjects_teacher"
    add_foreign_key_constraint "subjects", "teacher_id", "users", "id", :name => "fk_subjects_teacher"
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'  
    drop_table "roles_users"
    rename_table "users", "people"
    drop_table "roles"  

    change_column :people, :login, :string, :limit => 20
    add_column :people, :password, :string, :limit => 20
    change_column :people, :email, :string, :limit => 20
    remove_column :people, :crypted_password
    remove_column :people, :salt
    remove_column :people, :created_at
    remove_column :people, :updated_at
    remove_column :people, :activation_code
    remove_column :people, :activated_at
    remove_column :people, :password_reset_code
    
    remove_foreign_key_constraint "grades", "fk_grades_student"
    add_foreign_key_constraint "grades", "student_id", "students", "id", :name => "fk_grades_student", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "phone_numbers", "fk_numbers_person"
    remove_index "phone_numbers", :name => "fk_numbers_person"
    rename_column :phone_numbers, :user_id, :person_id
    add_index "phone_numbers", ["person_id"], :name => "fk_numbers_person"
    add_foreign_key_constraint "phone_numbers", "person_id", "people", "id", :name => "fk_numbers_person", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "students_subjects", "fk_ss_student"
    remove_foreign_key_constraint "students_subjects", "fk_ss_subject"
    remove_index "students_subjects", :name => "fk_ss_student"
    add_index "students_subjects", ["student_id"], :name => "fk_ps_student"
    remove_index "students_subjects", :name => "fk_ss_subject"
    add_index "students_subjects", ["subject_id"], :name => "fk_ps_subject"    
    add_foreign_key_constraint "students_subjects", "student_id", "people", "id", :name => "fk_ps_student", :on_update => nil, :on_delete => nil
    add_foreign_key_constraint "students_subjects", "subject_id", "subjects", "id", :name => "fk_ps_subject", :on_update => nil, :on_delete => nil

    remove_foreign_key_constraint "subjects", "fk_subjects_teacher"
    add_foreign_key_constraint "subjects", "teacher_id", "people", "id", :name => "fk_subjects_teacher"    
    execute 'SET FOREIGN_KEY_CHECKS = 1'
  end
end
