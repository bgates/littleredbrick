# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110216090826) do

  create_table "absences", :force => true do |t|
    t.integer "rollbook_entry_id"
    t.integer "student_id"
    t.integer "section_id"
    t.integer "code"
    t.date    "date"
  end

  create_table "assignments", :force => true do |t|
    t.integer  "section_id",                                             :null => false
    t.string   "title",                   :limit => 100, :default => "", :null => false
    t.text     "description"
    t.date     "date_assigned"
    t.date     "date_due"
    t.string   "category",                :limit => 20
    t.integer  "reported_grade_id"
    t.integer  "position",                                               :null => false
    t.integer  "point_value",                            :default => 0
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  add_index "assignments", ["category", "section_id"], :name => "index_assignments_on_section_id_and_category"
  add_index "assignments", ["position", "section_id"], :name => "index_assignments_on_section_id_and_position"
  add_index "assignments", ["reported_grade_id"], :name => "index_assignments_on_reported_grade_id"

  create_table "authorizations", :force => true do |t|
    t.integer  "user_id"
    t.string   "login",            :limit => 60
    t.string   "crypted_password", :limit => 40
    t.string   "salt",             :limit => 40
    t.integer  "school_id"
    t.string   "login_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authorizations", ["login", "school_id"], :name => "index_authorizations_on_login_and_school_id"
  add_index "authorizations", ["user_id"], :name => "index_authorizations_on_user_id"

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "delayed_jobs_locked_by"
  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "departments", :force => true do |t|
    t.string  "name",      :limit => 30, :default => "", :null => false
    t.integer "school_id"
  end

  add_index "departments", ["name", "school_id"], :name => "index_departments_on_school_id"

  create_table "events", :force => true do |t|
    t.string  "name",           :limit => 60,  :default => "", :null => false
    t.string  "description",    :limit => 256, :default => "", :null => false
    t.date    "date",                                          :null => false
    t.integer "creator_id"
    t.string  "invitable_type", :limit => 10
    t.integer "invitable_id"
  end

  add_index "events", ["creator_id"], :name => "index_events_on_creator_id"
  add_index "events", ["date", "invitable_id", "invitable_type"], :name => "index_events_on_invitable_type_and_invitable_id_and_date"

  create_table "forum_activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "posts_count",                    :default => 0
    t.integer  "discussable_id"
    t.string   "discussable_type", :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forum_activities", ["discussable_id", "discussable_type", "user_id"], :name => "by_all"

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",                   :default => 0
    t.integer "posts_count",                    :default => 0
    t.integer "position"
    t.text    "description_html"
    t.integer "discussable_id"
    t.string  "discussable_type", :limit => 10
    t.integer "owner_id"
    t.boolean "open"
  end

  add_index "forums", ["discussable_id", "discussable_type", "position"], :name => "by_discussable_and_position"
  add_index "forums", ["owner_id"], :name => "index_forums_on_owner_id"

  create_table "grades", :force => true do |t|
    t.integer "assignment_id",                  :default => 0
    t.integer "rollbook_entry_id"
    t.string  "score",             :limit => 5
    t.date    "updated_at"
    t.integer "section_id"
    t.date    "date_due"
  end

  add_index "grades", ["assignment_id"], :name => "fk_grades_assignment"
  add_index "grades", ["rollbook_entry_id"], :name => "fk_grades_student"
  add_index "grades", ["section_id"], :name => "index_grades_on_section_id"

  create_table "invites", :force => true do |t|
    t.integer "event_id",                                     :null => false
    t.integer "invitable_id",                                 :null => false
    t.string  "invitable_type", :limit => 10, :default => "", :null => false
  end

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.text     "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "logins", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "logout"
  end

  add_index "logins", ["created_at", "user_id"], :name => "index_logins_on_user_id_and_created_at"

  create_table "marking_periods", :force => true do |t|
    t.integer "track_id"
    t.date    "start"
    t.date    "finish"
    t.integer "reported_grade_id"
    t.integer "position"
  end

  add_index "marking_periods", ["reported_grade_id"], :name => "index_marking_periods_on_reported_grade_id"
  add_index "marking_periods", ["start", "track_id"], :name => "index_marking_periods_on_track_id"

  create_table "milestones", :force => true do |t|
    t.integer "rollbook_entry_id"
    t.decimal "earned",            :precision => 5, :scale => 1, :default => 0.0
    t.integer "possible",                                        :default => 0
    t.integer "reported_grade_id"
  end

  add_index "milestones", ["reported_grade_id"], :name => "index_milestones_on_reported_grade_id"
  add_index "milestones", ["rollbook_entry_id"], :name => "index_milestones_on_rollbook_entry_id"

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"
  add_index "moderatorships", ["user_id"], :name => "index_moderatorships_on_user_id"

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.boolean "active"
  end

  add_index "monitorships", ["topic_id"], :name => "index_monitorships_on_topic_id"
  add_index "monitorships", ["user_id"], :name => "index_monitorships_on_user_id"

  create_table "parents_students", :id => false, :force => true do |t|
    t.integer "parent_id",  :null => false
    t.integer "student_id", :null => false
  end

  add_index "parents_students", ["parent_id"], :name => "index_parents_students_on_parent_id"
  add_index "parents_students", ["student_id"], :name => "index_parents_students_on_student_id"

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
    t.integer  "discussable_id"
    t.string   "discussable_type", :limit => 10
  end

  add_index "posts", ["created_at", "discussable_id", "discussable_type", "user_id"], :name => "by_user_id_and_discussable"
  add_index "posts", ["created_at", "discussable_id", "discussable_type"], :name => "by_discuss_and_date"
  add_index "posts", ["created_at", "forum_id"], :name => "index_posts_on_forum_id_and_created_at"
  add_index "posts", ["created_at", "topic_id"], :name => "index_posts_on_topic_id"

  create_table "reported_grades", :force => true do |t|
    t.integer "reportable_id"
    t.string  "reportable_type", :limit => 10
    t.string  "description"
    t.integer "predecessor_id"
  end

  add_index "reported_grades", ["reportable_id", "reportable_type"], :name => "index_reported_grades_on_reportable_type_and_reportable_id"

  create_table "roles", :force => true do |t|
    t.string "title", :limit => 20
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_user_id_and_role_id"

  create_table "rollbook_entries", :force => true do |t|
    t.integer  "student_id", :default => 0
    t.integer  "section_id"
    t.integer  "position"
    t.integer  "x"
    t.integer  "y"
    t.datetime "created_at"
  end

  add_index "rollbook_entries", ["position", "section_id"], :name => "index_rollbook_entries_on_section_id_and_position"
  add_index "rollbook_entries", ["student_id"], :name => "fk_ss_student"

  create_table "schools", :force => true do |t|
    t.string  "name",          :limit => 100
    t.string  "domain_name",   :limit => 50
    t.integer "low_grade"
    t.integer "high_grade"
    t.integer "teacher_limit"
    t.boolean "setup"
  end

  add_index "schools", ["domain_name"], :name => "index_schools_on_domain_name"

  create_table "sections", :force => true do |t|
    t.integer "teacher_id"
    t.string  "time",         :limit => 3
    t.integer "subject_id"
    t.integer "track_id"
    t.text    "grade_scale"
    t.integer "enrollment",                :default => 0
    t.integer "posts_count",               :default => 0
    t.integer "topics_count",              :default => 0
    t.boolean "current"
  end

  add_index "sections", ["subject_id"], :name => "fk_sections_subject"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :limit => 32
    t.text     "data"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "subjects", :force => true do |t|
    t.string  "name",          :limit => 100, :default => "", :null => false
    t.string  "credit",        :limit => 3
    t.integer "department_id"
  end

  add_index "subjects", ["department_id", "name"], :name => "index_subjects_on_department_id_and_name"

  create_table "terms", :force => true do |t|
    t.integer "school_id"
    t.integer "low_period"
    t.integer "high_period"
  end

  add_index "terms", ["id", "school_id"], :name => "index_terms_on_school_id_and_id"

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",         :default => 0
    t.integer  "sticky",       :default => 0
    t.integer  "posts_count",  :default => 0
    t.datetime "replied_at"
    t.integer  "replied_by"
    t.integer  "last_post_id"
    t.boolean  "locked"
  end

  add_index "topics", ["forum_id", "replied_at", "sticky"], :name => "index_topics_on_forum_id_and_sticky_and_replied_at"
  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  add_index "topics", ["user_id"], :name => "index_topics_on_user_id"

  create_table "tracks", :force => true do |t|
    t.integer "term_id"
    t.date    "archive"
    t.integer "position"
  end

  add_index "tracks", ["term_id"], :name => "index_tracks_on_term_id"

  create_table "users", :force => true do |t|
    t.string   "type",       :limit => 10,  :default => ""
    t.integer  "school_id",                 :default => 0
    t.integer  "id_number"
    t.string   "first_name", :limit => 25
    t.string   "last_name",  :limit => 25
    t.string   "title",      :limit => 10
    t.string   "email",      :limit => 100
    t.integer  "grade"
    t.datetime "last_login"
  end

  add_index "users", ["last_name", "school_id", "type"], :name => "index_users_on_school_id_and_type_and_last_name"

end
