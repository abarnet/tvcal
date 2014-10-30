class TVCal < Sinatra::Base
  r = RethinkDB::RQL.new

  def require_auth!
    unless env['warden'].authenticated?
      redirect '/auth/login'
    end
  end

  get '/' do
    require_auth!
    @airings = r.table('airings')
      .filter({'AiringType' => 'New'})
      .order_by('AiringTime')
      .run(@rdb_connection).to_a

    @events = @airings.map do |a|
      {
        title: a['Title'],
        episode_number: "s#{(a['season'] || "").rjust(2, '0')}e#{(a['episode'] || "").rjust(2, '0')}",
        start: a['AiringTime'].to_i,
        end: (a['AiringTime'] + a['Duration'].to_i * 60).to_i,
        copy: a['Copy'],
        channel: a['SourceLongName'],
        episode_title: a['EpisodeTitle']
      }
    end
    @nav_tab = "calendar"
    erb "index.html".to_sym
  end

  get '/calendar.ics' do
    @airings = r.table('airings').order_by('AiringTime').run(@rdb_connection).to_a
    response.headers['Content-type'] = 'text/calendar; charset=utf-8'
    response.headers['Content-Disposition'] = 'inline; filename=calendar.ics'

    erb "calendar.ics".to_sym
  end

  get '/shows' do
    require_auth!
    @shows = r.table('shows').order_by('title').run(@rdb_connection).to_a
    @nav_tab = 'shows'
    erb "shows.html".to_sym
  end

  post '/shows' do
    require_auth!
    title = params['title']
    search = Search.new(settings.credentials['search'])
    info = search.find_title(title)
    r.table('shows').insert(info).run(@rdb_connection)

    redirect to('/shows')
  end

  delete '/shows/:series_id' do
    require_auth!
    series_id = params['series_id']
    r.table('airings').filter({series_id: series_id}).delete.run(@rdb_connection)
    r.table('shows').get(series_id).delete.run(@rdb_connection)
    status 204
  end

  get '/search/:query' do
    require_auth!
    search = Search.new(settings.credentials['search'])
    info = search.find_title(params[:query])
    return info.to_json
  end

  get '/series/:series_id' do
    require_auth!
    series = r.table('shows').get(params[:series_id]).run(@rdb_connection)
    listings = Listings.new(settings.credentials['listings']['key'])
    airings = listings.airings(series)
    return airings.to_json
  end

  get '/delete' do
    require_auth!
    c = r.connect(:host=> RDB_CONFIG[:host], :port=>RDB_CONFIG[:port])
    r.db_drop(settings.db).run(c)
    c.close()
    return "Dropped db"
  end

  get '/populate_data' do
    require_auth!

    tvdata = TVData.new(settings.credentials)
    results = tvdata.fetch_data(@rdb_connection)

    results.to_json
    redirect to('/')
  end
end