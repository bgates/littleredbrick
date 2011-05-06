class IHateForeignKeys < ActiveRecord::Migration
  def self.up
    fk = {'assignments' => ['subject'], 'grades' => ['student','assignment'],'sections' => ['teacher','subject'],'subjects' => ['department']}
    fk.each do |table,keys|
      keys.each do |key|
        execute "ALTER TABLE #{table} DROP FOREIGN KEY fk_#{table}_#{key};"
      end
    end
    fk2 = {'phones' => ['numbers_person'], 'roles_users' => ['ru_user','ru_role'], 'rollbook_entries' => ['ss_student', 'ss_section']}
    fk2.each do |table,keys|
      keys.each do |key|
        execute "ALTER TABLE #{table} DROP FOREIGN KEY fk_#{key};"
      end
    end  
  end

  def self.down
  end
end
