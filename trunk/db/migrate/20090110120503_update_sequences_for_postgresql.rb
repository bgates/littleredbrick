class UpdateSequencesForPostgresql < ActiveRecord::Migration
  def self.up
    set_id_tables = ActiveRecord::Base.connection.tables.sort.reject! do |tbl|
      ['schema_migrations', 'parents_students', 'roles_users'].include?(tbl)
    end
    # Set the sequence to the highest of inserted records.
    set_id_tables.each do |tbl|
      execute "select setval('#{tbl}_id_seq', (select max(id) from #{tbl}));"
    end
  end

  def self.down
  end
end
