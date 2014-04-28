require 'bundler'
Bundler.require

require 'bcrypt'
require 'yaml'
require 'sinatra/asset_pipeline'

require_relative 'config/rdb_config'

['tv', 'classes'].each do |folder|
  Dir[File.dirname(__FILE__) + "/#{folder}/*.rb"].each {|file| require file }
end

class TVCal < Sinatra::Base
  enable :sessions

  set :root, File.dirname(__FILE__) # You must set app root

  # must define pipeline settings before register call
  set :assets_precompile, %w(app.js app.css)
  set :assets_js_compressor, :yui
  set :assets_css_compressor, :yui
  register Sinatra::AssetPipeline

  logger = Logger.new(File.join(File.dirname(__FILE__), 'log/sinatra.log'))
  use Rack::CommonLogger, logger

  configure do
    enable :logging

    set :db, RDB_CONFIG::DB

    r = RethinkDB::RQL.new
    begin
      c = r.connect(:host=> RDB_CONFIG::HOST, :port=>RDB_CONFIG::PORT)
    rescue Exception => err
      puts "Cannot connect to RethinkDB database #{RDB_CONFIG::HOST}:#{RDB_CONFIG::PORT} (#{err.message})"
      Process.exit(1)
    end

    begin
      r.db_create(RDB_CONFIG::DB).run(c)
    rescue RethinkDB::RqlRuntimeError => err
      puts "Database already exists."
    end

    ['shows', 'airings', 'users'].each do |table|
      begin
        r.db(settings.db).table_create(table).run(c)
      rescue RethinkDB::RqlRuntimeError => err
        puts "table '#{table}' already exists."
      end
    end

    config = YAML.load_file("./config/credentials.yaml")

    set :session_secret, config['session_secret']
    set :credentials, config['rovi']

    config['default_users'].each do |name, password|
      r.db(settings.db).table('users').insert({id:name, password_hash: BCrypt::Password.create(password).to_str}).run(c)
    end
  
    c.close
  end

  before do
    begin
      r = RethinkDB::RQL.new
      @rdb_connection = RDB_CONFIG.connection(r) #r.connect(:host => RDB_CONFIG::HOST, :port => RDB_CONFIG::PORT, :db => settings.db)
      @user = env['warden'].authenticate
    rescue Exception => err
      logger.error "Cannot connect to RethinkDB database #{RDB_CONFIG::HOST}:#{RDB_CONFIG::PORT} (#{err.message})"
      halt 501, 'Database not available.'
    end
  end

  after do
    begin
      @rdb_connection.close if @rdb_connection
    rescue
      logger.warn "Couldn't close connection"
    end
  end
end

Dir[File.dirname(__FILE__) + '/routes/*.rb'].each {|file| require file }