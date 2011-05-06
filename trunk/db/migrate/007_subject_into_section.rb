class SubjectIntoSection < ActiveRecord::Migration
  def self.up
  
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    drop_table "departments_subject_names"
    rename_table 'subjects', 'sections'
    rename_table 'subject_names', 'subjects'
    rename_table 'students_subjects', 'sections_students'
    
    remove_foreign_key_constraint "sections_students", "fk_ss_subject"
    remove_index "sections_students", :name => :fk_ss_subject
    rename_column :sections_students, :subject_id, :section_id
    add_index "sections_students", ["section_id"], :name => "fk_ss_section"
    add_foreign_key_constraint "sections_students", "section_id", "sections", "id", :name => "fk_ss_section", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "sections", "fk_subjects_subject_name"
    remove_index "sections", :name => :fk_subjects_subject_name
    rename_column :sections, :subject_name_id, :subject_id
    add_index "sections", ["subject_id"], :name => "fk_sections_subject"
    add_foreign_key_constraint "sections", "subject_id", "subjects", "id", :name => "fk_sections_subject", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "sections", "fk_subjects_teacher"
    remove_index "sections", :name => :fk_subjects_teacher
    add_index "sections", ["teacher_id"], :name => "fk_sections_teacher"
    add_foreign_key_constraint "sections", "teacher_id", "users", "id", :name => "fk_sections_teacher", :on_update => nil, :on_delete => nil
        
    remove_foreign_key_constraint "sections", "fk_subjects_department"
    remove_index "sections", :name => :fk_subjects_department
    add_index "sections", ["department_id"], :name => "fk_sections_department"
    add_foreign_key_constraint "sections", "department_id", "departments", "id", :name => "fk_sections_department", :on_update => nil, :on_delete => nil
    
    remove_foreign_key_constraint "assignments", "fk_assignments_subject"
    remove_index "assignments", :name => :fk_assignments_subject
    rename_column :assignments, :subject_id, :section_id
    add_index "assignments", ["section_id"], :name => "fk_assignments_section"
    add_foreign_key_constraint "assignments", "section_id", "sections", "id", :name => "fk_assignments_subject", :on_update => nil, :on_delete => nil
   
    add_column :subjects, :credit, :float
    add_column "subjects", "department_id", :integer
    add_index "subjects", ["department_id"], :name => "fk_subjects_department"
    add_foreign_key_constraint "subjects", "department_id", "departments", "id", :name => "fk_subjects_department", :on_update => nil, :on_delete => nil
        
    execute 'SET FOREIGN_KEY_CHECKS = 1' 
  end
###there are a lot of indices and fks that need to be changed for the down migration
  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    remove_column :subjects, :credit
    rename_column :assignments, :section_id, :subject_id
    
    remove_index "sections_students", "section_id"
    remove_foreign_key_constraint "sections_students", "fk_ss_section"
    rename_column :sections_students, :section_id, :subject_id
    add_index "sections_students", ["subject_id"], :name => "fk_ss_subject"
    add_foreign_key_constraint "sections_students", "subject_id", "subjects", "id", :name => "fk_ss_subject", :on_update => nil, :on_delete => nil
    
    remove_index "assignments", "section_id"
    remove_foreign_key_constraint "assignments", "section_id"
    rename_column :sections, :subject_id, :subject_name_id
    add_index "assignments", ["subject_id"], :name => "fk_assignment_subject"
    add_foreign_key_constraint "assignments", "subject_id", "subjects", "id", :name => "fk_assignments_subject", :on_update => nil, :on_delete => nil
   
    rename_table 'subjects', 'subject_names'
    rename_table 'students_sections', 'students_subjects' 
    rename_table 'sections', 'subjects'   
    create_table "departments_subject_names", :id => false, :force => true do |t|
      t.column :department_id, :integer
      t.column :subject_name_id, :integer
    end     
    add_index "departments_subject_names", ["department_id"], :name => "fk_ds_department"
    add_index "departments_subject_names", ["subject_name_id"], :name => "fk_ds_subject_name"
    add_foreign_key_constraint "departments_subject_names", "department_id", "departments", "id", :name => "fk_ds_department", :on_update => nil, :on_delete => nil
    add_foreign_key_constraint "departments_subject_names", "subject_name_id", "subject_names", "id", :name => "fk_ds_subject_name", :on_update => nil, :on_delete => nil

    execute 'SET FOREIGN_KEY_CHECKS = 1' 
  end
end
