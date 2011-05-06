class AddMoreIndexes < ActiveRecord::Migration
  def self.up

    change_column :users, :type, :string, :limit => 10
    remove_index :users, :school_id
    remove_index :users, [:school_id, :type]
    add_index :users, [:school_id, :type, :last_name]

    add_index :moderatorships, :user_id

    add_index :posts, [:forum_id, :created_at]
    remove_index :posts, :forum_id

    add_index :topics, [:forum_id, :sticky, :replied_at]
    remove_index :topics, :forum_id
    remove_index :topics, [:sticky, :replied_at]

    add_index :forums, [:discussable_type, :discussable_id, :position], :name => 'by_discussable_and_position'
    remove_index :forums, [:discussable_type, :discussable_id]

    add_index :assignments, [:section_id, :category]

    change_column :forum_activities, :discussable_type, :string, :limit => 10
    add_index :forum_activities, [:discussable_type, :discussable_id, :user_id], :name => 'by_all'

    remove_index :posts, :name => :index_posts_on_user_id
    add_index :posts, [:discussable_type, :discussable_id, :user_id, :created_at], :name => 'by_user_id_and_discussable'

    change_column :assignments, :position, :integer, :limit => 3, :null => false
    change_column :assignments, :section_id, :integer, :limit => 5, :null => false
    remove_index :assignments, :section_id
    add_index :assignments, [:section_id, :position]

    remove_index :rollbook_entries, :name => :fk_ss_section
    add_index :rollbook_entries, [:section_id, :position]

    remove_index :subjects, :name => :fk_subjects_department
    add_index  :subjects, [:department_id, :name]

    remove_index :logins, :user_id
    add_index :logins, [:user_id, :created_at]

    remove_index :roles_users, :role_id
    remove_index :roles_users, :user_id
    add_index :roles_users, [:user_id, :role_id]

    remove_index :terms, :school_id
    add_index :terms, [:school_id, :id]

    change_column :events, :invitable_type, :string, :limit => 10

    remove_index :posts, :name => :index_posts_on_discussable_type_and_discussable_id
    add_index :posts, [:discussable_id, :discussable_type, :created_at], :name => 'by_discuss_and_date'

    change_column :users, :title, :string, :limit => 10
  end

  def self.down

    add_index :users, :school_id
    add_index :users, [:school_id, :type]
    remove_index :users, [:school_id, :type, :last_name]

    remove_index :moderatorships, :user_id

    remove_index :posts, [:forum_id, :created_at]
    add_index :posts, :forum_id

    remove_index :topics, [:forum_id, :sticky, :replied_at]
    add_index :topics, :forum_id
    add_index :topics, [:sticky, :replied_at]

    remove_index :forums, :name => 'by_discussable_and_position'
    add_index :forums, [:discussable_type, :discussable_id]

    remove_index :forum_activities, :name => 'by_all'

    remove_index :posts, :name => 'by_user_id_and_discussable'
    add_index :posts, :user_id

    add_index :assignments, :section_id
    remove_index :assignments, [:section_id, :position]
    remove_index :assignments, [:section_id, :category]

    add_index :rollbook_entries, :section_id, :name => 'fk_ss_section'
    remove_index :rollbook_entries, [:section_id, :position]

    add_index :subjects, :department_id, :name => 'fk_subjects_department'
    remove_index  :subjects, [:department_id, :name]

    remove_index :logins, [:user_id, :created_at]
    add_index :logins, :user_id

    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    remove_index :roles_users, [:user_id, :role_id]

    add_index :terms, :school_id
    remove_index :terms, [:school_id, :id]

    remove_index :posts, :name => 'by_discuss_and_date'
    add_index :posts, [:discussable_type, :discussable_id]

    change_column :users, :title, :string, :limit => 3
  end
end
