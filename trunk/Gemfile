source 'http://rubygems.org'

gem 'rails', '3.0.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'pg'
# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

gem 'hpricot' #required for GData
gem 'GData'
gem 'rubyzip' #required for roo
gem 'nokogiri' #required for roo
gem 'spreadsheet' #required for roo
gem 'google-spreadsheet-ruby'
gem 'libxml-ruby'
gem 'roo'#, :git => "http://github.com/sr3d/roo.git"
gem 'packet'
gem 'RedCloth', '>= 4.1.9', :require => 'redcloth'
gem 'ruby-ole'
gem 'will_paginate', '>=3.0.pre'
gem 'mocha', '>=0.9.10', :require => false
gem 'map_by_method'
gem 'what_methods'

gem 'activerecord-import', '>= 0.2.0'
gem 'delayed_job'

gem 'factory_girl_rails', :git => "http://github.com/CodeMonkeySteve/factory_girl_rails.git"

gem 'paperclip'
# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
group :development, :test do
  gem 'silent-postgres'
  gem 'cover_me'
end

group :test do
  gem 'spork'
  gem 'webrat'
end
