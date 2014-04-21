#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# require File.expand_path('../config/application', __FILE__)

#require_relative 'config/rdb_config'
#require_relative 'tv/tv_data'
#require File.expand_path('../tv/tv_data', __FILE__)

# sinatra assetpack
# APP_FILE  = 'app.rb'
# APP_CLASS = 'TVCal'
# require 'sinatra/assetpack/rake'



require 'sinatra/asset_pipeline/task'
require './app'

Sinatra::AssetPipeline::Task.define! TVCal

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| load r}