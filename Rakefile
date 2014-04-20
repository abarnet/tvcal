#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# require File.expand_path('../config/application', __FILE__)

require_relative 'config/rdb_config'
require_relative 'tv/tv_data'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| load r}