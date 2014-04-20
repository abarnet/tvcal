require_relative 'listings'
require 'rethinkdb'

class TVData
    def initialize(key)
        @key = key
    end

    def fetch_data(rdb_connection)
        r = RethinkDB::RQL.new

        listings = Listings.new(@key)#settings.credentials['listings']['key'])

        results = []

        series = r.table('shows').run(rdb_connection).to_a
        series.to_json
        series.each do |s|
          last_fetch = s['last_fetch']
          if !last_fetch.nil? and Time.now - last_fetch < 20 * 60 * 60
            next
          end

          airings = listings.airings s
          results << r.table('airings').insert(airings, upsert: true).run(rdb_connection)

          s['last_fetch'] = Time.now
          r.table('shows').get(s['id']).update(s).run(rdb_connection)
        end
        return results
    end
end