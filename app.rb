require 'bundler'
Bundler.require

require 'bcrypt'
require 'yaml'

['tv', 'classes'].each do |folder|
  Dir[File.dirname(__FILE__) + "/#{folder}/*.rb"].each {|file| require file }
end

class TVCal < Sinatra::Base
  enable :sessions

  RDB_CONFIG = {
    :host => ENV['RDB_HOST'] || 'localhost',
    :port => ENV['RDB_PORT'] || 28015,
    :db   => ENV['RDB_DB']   || 'tv'
  }
 
  configure do
    set :db, RDB_CONFIG[:db]

    r = RethinkDB::RQL.new
    begin
      c = r.connect(:host=> RDB_CONFIG[:host], :port=>RDB_CONFIG[:port])
    rescue Exception => err
      puts "Cannot connect to RethinkDB database #{RDB_CONFIG[:host]}:#{RDB_CONFIG[:port]} (#{err.message})"
      Process.exit(1)
    end

    begin
      r.db_create(RDB_CONFIG[:db]).run(c)
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
      @rdb_connection = r.connect(:host => RDB_CONFIG[:host], :port => RDB_CONFIG[:port], :db => settings.db)
    rescue Exception => err
      logger.error "Cannot connect to RethinkDB database #{RDB_CONFIG[:host]}:#{RDB_CONFIG[:port]} (#{err.message})"
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