
class TVCal < Sinatra::Base
  use Warden::Manager do |config|
    # serialization must be to string
    config.serialize_into_session{|user| user.select{|k| k == 'id'}.to_json }
    config.serialize_from_session{|user_json| JSON.parse(user_json) }

    config.scope_defaults :default,
      strategies: [:password],

      # action for failed authentication
      action: 'auth/unauthenticated'

    config.failure_app = self
  end

  # Warden::Manager.before_failure do |env,opts|
  #   env['REQUEST_METHOD'] = 'POST'
  # end

  Warden::Strategies.add(:password) do
    def valid?
      params['user'] && params['user']['username'] && params['user']['password']
    end

    def authenticate!
      r = RethinkDB::RQL.new
      c = RDB_CONFIG.connection(r)#r.connect(host: RDB_CONFIG[:host], port: RDB_CONFIG[:port], db: RDB_CONFIG[:db])
      user = r.table('users').get(params['user']['username']).run(c)
      c.close
      
      if user.nil?
        fail!("The username you entered does not exist.")
      elsif BCrypt::Password.new(user['password_hash']) == params['user']['password']
        success!(user)
      else
        fail!("Could not log in")
      end
    end
  end

  get '/auth/login' do
    @nav_tab = 'login'
    erb :login
  end

  post '/auth/login' do
    env['warden'].authenticate!

    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end

  post '/auth/unauthenticated' do
    @nav_tab = 'login'    
    erb :login
  end

  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    #flash.success = 'Successfully logged out'
    redirect '/'
  end

end