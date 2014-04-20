require 'yaml'

namespace :tv do
    desc "fetch"
    task :fetch do 
        r = RethinkDB::RQL.new
        key = YAML.load_file("./config/credentials.yaml")['rovi']['listings']['key']
        tvdata = TVData.new(key)
        tvdata.fetch_data(RDB_CONFIG::connection(r))
        puts 'done'
    end    
end