module RDB_CONFIG
  HOST = ENV['RDB_HOST'] || 'localhost'
  PORT = ENV['RDB_PORT'] || 28015
  DB   = ENV['RDB_DB']   || 'tv'

  def connection(r)
    r.connect(:host => HOST, :port => PORT, :db => DB)
  end

  module_function :connection
end
