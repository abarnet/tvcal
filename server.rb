require 'sinatra'
require 'rethinkdb'
require 'yaml'
load './fetch.rb'
require 'sinatra/reloader' 


RDB_CONFIG = {
  :host => ENV['RDB_HOST'] || 'localhost', 
  :port => ENV['RDB_PORT'] || 28015,
  :db   => ENV['RDB_DB']   || 'tv'
}

r = RethinkDB::RQL.new


class Time
    def local 
        self + Time.zone_offset('EDT')
    end
end

configure do 
    set :db, RDB_CONFIG[:db]

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

    begin
        r.db(settings.db).table_create('shows').run(c)
    rescue RethinkDB::RqlRuntimeError => err
        puts "Shows table already exists."
    end

    begin
        r.db(settings.db).table_create('airings').run(c)
    rescue RethinkDB::RqlRuntimeError => err
        puts "Airings table already exists."
    ensure
        c.close
    end

    set :credentials, YAML.load_file("./credentials.yaml")['rovi']
end

before do
    begin
        @rdb_connection = r.connect(:host => RDB_CONFIG[:host], :port => RDB_CONFIG[:port], :db => settings.db)
    rescue Exception => err
        logger.error "Cannot connect to RethinkDB database #{RDB_CONFIG[:host]}:#{RDB_CONFIG[:port]} (#{err.message})"
        halt 501, 'This page could look nicer, unfortunately the error is the same: database not available.'
    end
end
 
after do
    begin
        @rdb_connection.close if @rdb_connection
    rescue
        logger.warn "Couldn't close connection"
    end
end


get '/' do
    @airings = r.table('airings').order_by('AiringTime').run(@rdb_connection).to_a
    erb "index.html".to_sym
end  

get '/calendar.ics' do
    @airings = r.table('airings').order_by('AiringTime').run(@rdb_connection).to_a
    erb "calendar.ics".to_sym
end

get '/shows' do
    @shows = r.table('shows').order_by('title').run(@rdb_connection).to_a
    erb "shows.html".to_sym
end

post '/shows' do
    title = params['title']
    search = Search.new(settings.credentials)
    info = seach::find_title(title)
    r.table('shows').insert(info).run(@rdb_connection)

    redirect to('/shows')
end


get '/search/:query' do

    search = Search.new(settings.credentials['search'])    
    info = search.find_title(params[:query])
    return info.to_json
    #return  r.table('shows').insert(info).run(@rdb_connection).to_json
end

get '/series/:series_id' do
    series = r.table('shows').get(params[:series_id]).run(@rdb_connection)
    listings = Listings.new(settings.credentials['listings']['key'])
    airings = listings.airings(series)
    return airings.to_json
end


get '/delete' do
    c = r.connect(:host=> RDB_CONFIG[:host], :port=>RDB_CONFIG[:port])
    r.db_drop(settings.db).run(c)
    c.close()
    return "Dropped db"
end

get '/populate_data' do
    #titles = ["Orphan Black", "Community"]

    listings = Listings.new(settings.credentials['listings']['key'])

    results = []

    series = r.table('shows').run(@rdb_connection).to_a
    series.to_json
    series.each do |s|
        last_fetch = s['last_fetch']
        if !last_fetch.nil? and Time.now - last_fetch < 20 * 60 * 60
            next
        end

        airings = listings.airings s       
        results << r.table('airings').insert(airings, upsert: true).run(@rdb_connection)

        s['last_fetch'] = Time.now
        r.table('shows').get(s['id']).update(s).run(@rdb_connection)
    end

    results.to_json
    redirect to('/')
end


