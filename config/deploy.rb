require 'bundler/capistrano'
set :application,         "littleredbrick"
set :user,                "deploy"                  
set :use_sudo,            false
set :domain,              "173.230.132.11"

set :scm,                 "git"
set :repository,          "git@github.com:bgates/littleredbrick.git"

set :git_shallow_clone,   1
set :keep_releases,       5

set :deploy_to,           "/srv/www/#{application}"          

set :runner,              "deploy"

ssh_options[:paranoid]    = false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
#set :deploy_via, :checkout                # was :copy when the svn was local - pack up the files and send them
#set :copy_strategy, :export           # I think the export option removes the .svn dirs before they go to the server


role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :rails_env, :production
set :unicorn_binary, "/usr/bin/unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid,    "#{current_path}/tmp/pids/unicorn.pid"

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/unicorn start /etc/unicorn/littleredbrick.conf"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/unicorn stop /etc/unicorn/littleredbrick.conf"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end
