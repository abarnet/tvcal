class TVCal < Sinatra::Base
  r = RethinkDB::RQL.new

  get '/' do
    env['warden'].authenticate!
    @airings = r.table('airings').order_by('AiringTime').run(@rdb_connection).to_a
    erb "index.html".to_sym
  end

  get '/calendar.ics' do
    @airings = r.table('airings').order_by('AiringTime').run(@rdb_connection).to_a
    response.headers['Content-type'] = 'text/calendar; charset=utf-8'
    response.headers['Content-Disposition'] = 'inline; filename=calendar.ics'

    erb "calendar.ics".to_sym
  end

  get '/shows' do
    env['warden'].authenticate!
    @shows = r.table('shows').order_by('title').run(@rdb_connection).to_a
    erb "shows.html".to_sym
  end

  post '/shows' do
    env['warden'].authenticate!
    title = params['title']
    search = Search.new(settings.credentials)
    info = search::find_title(title)
    r.table('shows').insert(info).run(@rdb_connection)

    redirect to('/shows')
  end

  get '/search/:query' do
    env['warden'].authenticate!
    search = Search.new(settings.credentials['search'])
    info = search.find_title(params[:query])
    return info.to_json
  end

  get '/series/:series_id' do
    env['warden'].authenticate!
    series = r.table('shows').get(params[:series_id]).run(@rdb_connection)
    listings = Listings.new(settings.credentials['listings']['key'])
    airings = listings.airings(series)
    return airings.to_json
  end

  get '/delete' do
    env['warden'].authenticate!
    c = r.connect(:host=> RDB_CONFIG[:host], :port=>RDB_CONFIG[:port])
    r.db_drop(settings.db).run(c)
    c.close()
    return "Dropped db"
  end

  get '/populate_data' do
    env['warden'].authenticate!
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
end