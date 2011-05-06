set :application, "littleredbrick"
set :domain, "littleredbrick.net"
set :user, "root"                  # Your HostingRails username
set :repository,  "svn+ssh://#{user}@#{domain}/srv/svn/#{application}"
#set :repository, "file:///home/svn/littleredbrick/trunk"
#set :repository,  "file:///c:/svn-repos/lrb/trunk" #assumes uname/pwd for svn account same as for deploy user; this was what I used for Windows

#set :use_sudo, false                	# HostingRails users don't have sudo access
set :deploy_to, "/srv/www/#{application}"          # Where on the server your app will be deployed
set :deploy_via, :checkout                # was :copy when the svn was local - pack up the files and send them
set :copy_strategy, :export           # I think the export option removes the .svn dirs before they go to the server
set :chmod755, %w(app config db lib public vendor script script/*) 	# Some files that will need proper permissions
# set :mongrel_port, "4444"                # Mongrel port that was assigned to you
# set :mongrel_nodes, "4"                # Number of Mongrel instances for those with multiple Mongrels

default_run_options[:pty] = true

role :app, domain
role :web, domain
role :db,  domain, :primary => true

# set :scm, :subversion
desc "Set the proper permissions for directories and files on HostingRails accounts"
task :after_update_code do
  chmod755.each do |item|
    run "chmod 755 #{release_path}/#{item}"
  end
  run "chown -R nobody #{release_path}"
  transaction do
    edit_for_hostingrails
  end
end

task :edit_for_hostingrails do
  require 'tempfile'
  #attempt to automate file changes required before deployment
  lines = IO.readlines('config/environment.rb')
  env = Tempfile.new('env')
  lines.each do |line|
    line.sub!(/#/,'') if line =~ /ENV\['RAILS_ENV'/
    env.puts line
  end
  env.close
  env.open
  put(env.read, "#{release_path}/config/environment.rb")#, :mode => 664)
  
  env.close(true)
  lines = IO.readlines('config/database.yml')
  file = Tempfile.new('db')
  lines.each do |line|
    line.sub!(/.*##/, '')
    file.puts line
  end
  file.close
  file.open
  put(file.read, "#{release_path}/config/database.yml")
  file.close(true)
end
