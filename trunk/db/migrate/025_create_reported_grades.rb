class CreateReportedGrades < ActiveRecord::Migration
  def self.up
    create_table :reported_grades do |t|
      t.column :reportable_id, :integer
      t.column :reportable_type, :string
      t.column :description, :string
      t.column :position, :integer
    end

    add_column :marking_periods, :reported_grade_id, :integer

    add_column :milestones, :reported_grade_id, :integer
    remove_column :milestones, :description

    remove_column :terms, :grades

    rename_column :assignments, :marking_period, :reported_grade_id
    change_column :assignments, :reported_grade_id, :integer

    remove_column :sections, :reported_grades

    remove_column :milestones, :section_id
    rename_column :milestones, :student_id, :rollbook_entry_id

    rename_column :grades, :student_id, :rollbook_entry_id

  end

  def self.down
    drop_table :reported_grades
    remove_column :marking_periods, :reported_grade_id
    add_column :milestones, :description, :string
    remove_column :milestones, :reported_grade_id
    add_column :terms, :grades, :text
    rename_column :assignments, :reported_grade_id, :marking_period
    change_column :assignments, :marking_period, :integer, :length => 1
    add_column :sections, :reported_grades, :text
    add_column :milestones, :section_id, :integer
    rename_column :milestones, :rollbook_entry_id, :student_id
    rename_column :grades, :rollbook_entry_id, :student_id
  end
end
