require_relative 'listings'
require 'rethinkdb'

class TVData
    def initialize(credentials)
        @credentials = credentials
    end

    def fetch_data(rdb_connection)
        r = RethinkDB::RQL.new

        listings = Listings.new(@credentials['listings']['key'])#@key)#settings.credentials['listings']['key'])
        search = Search.new(@credentials['search'])

        results = []

        series = r.table('shows').run(rdb_connection).to_a
        series.to_json
        series.each do |s|
          last_fetch = s['last_fetch']
          if !last_fetch.nil? and Time.now - last_fetch < 20 * 60 * 60
            next# unless s['title'] == "Parenthood"
          end

          s['seasons'] = search.seasons_info s

          r.table('airings')
            .filter({'series_id' => s['id']})
            .filter {|a| a['AiringTime'] >= r.now() }
            .update({'AiringType' => 'Stale'})
            .run(rdb_connection)

          airings = listings.airings s

          results << r.table('airings')
            .insert(airings, conflict: 'replace')
            .run(rdb_connection)

          s['last_fetch'] = Time.now
          r.table('shows').get(s['id']).update(s).run(rdb_connection)
        end
        return results
    end
end