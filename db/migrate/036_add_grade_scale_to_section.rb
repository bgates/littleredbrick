class AddGradeScaleToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :grade_scale, :text
  end

  def self.down
    remove_column :sections, :grade_scale
  end
end
