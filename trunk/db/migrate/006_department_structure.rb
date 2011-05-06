class DepartmentStructure < ActiveRecord::Migration
  def self.up
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    add_column :departments, :school_id, :integer
    remove_column :departments, :subject
    add_column :subjects, :department_id, :integer
    add_column :subjects, :subject_name_id, :integer
    remove_column :subjects, :name
    remove_column :subjects, :department
    create_table "subject_names", :force => true do |t|
      t.column :name, :string, :limit => 100, :default => "", :null => false
    end   
    add_index "subjects", ["department_id"], :name => "fk_subjects_department"
    add_index "subjects", ["subject_name_id"], :name => "fk_subjects_subject_name"
    add_foreign_key_constraint "subjects", "department_id", "departments", "id", :name => "fk_subjects_department", :on_update => nil, :on_delete => nil
    add_foreign_key_constraint "subjects", "subject_name_id", "subject_names", "id", :name => "fk_subjects_subject_name", :on_update => nil, :on_delete => nil
    
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

  def self.down
    execute 'SET FOREIGN_KEY_CHECKS = 0'
    remove_column :departments, :school_id
    add_column :departments, :subject, :string, :limit => 100, :default => "", :null => false
    remove_column :subjects, :department_id
    remove_column :subjects, :subject_name_id
    add_column :subjects, :name, :string, :limit => 100, :default => "", :null => false
    add_column :subjects, :department, :string, :limit => 100, :default => "", :null => false
    drop_table "departments_subject_names"
    execute 'SET FOREIGN_KEY_CHECKS = 1'  
  end
end
