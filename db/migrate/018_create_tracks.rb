class CreateTracks < ActiveRecord::Migration
  def self.up

    create_table :terms do |t|
      t.column :name, :string
      t.column :school_id, :integer
      t.column :grades, :text
    end
    
    create_table :tracks do |t|
       t.column :name, :string
       t.column :term_id, :integer
       t.column :archive, :date
    end

    rename_column :marking_periods, :school_id, :track_id

    execute "alter table sections drop foreign key fk_sections_department"
    remove_column :sections, :department_id
    remove_column :sections, :location
    remove_column :sections, :credit

    add_column :sections, :current, :boolean
    add_column :sections, :track_id, :integer
    add_column :sections, :reported_grades, :text
  end

  def self.down
    drop_table :tracks
    drop_table :terms

    remove_column :sections, :current
    remove_column :sections, :track_id
    remove_column :sections, :reported_grades

    rename_column :marking_periods, :track_id, :school_id
    
    add_column :sections, :department_id, :integer
    add_column :sections, :location, :string
    add_column :sections, :credit, :float
    execute "alter table sections add foreign key fk_sections_department foreign key(department_id) references departments(id)"
  end
end
