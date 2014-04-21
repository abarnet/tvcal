require "capistrano/rvm"
require "capistrano/bundler"
require "whenever/capistrano"
# config valid only for Capistrano 3.1
lock '3.2.0'

set :application, 'tvcal'
set :repo_url, 'git@github.com:abarnet/tvcal.git'

set :pid_path, 'tmp/pids/rackup.pid'


    # for some reason I have to explicitly set all the whenever default values to get it to work
    set :whenever_roles,        ->{ :db }
    set :whenever_command,      ->{ [:bundle, :exec, :whenever] }
    set :whenever_command_environment_variables, ->{ {} }
    set :whenever_identifier,   ->{ fetch :application }
    set :whenever_environment,  ->{ fetch :rails_env, "production" }
    set :whenever_variables,    ->{ "environment=#{fetch :whenever_environment}" }
    set :whenever_update_flags, ->{ "--update-crontab #{fetch :whenever_identifier} --set #{fetch :whenever_variables}" }
    set :whenever_clear_flags,  ->{ "--clear-crontab #{fetch :whenever_identifier}" }

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/credentials.yaml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Start TVCal with Rack'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; #{fetch :rvm_custom_path}/bin/rvm #{fetch :rvm_ruby_version} do bundle exec rackup -o 0.0.0.0 -s thin -E production -D -P #{fetch :pid_path}"
    end
  end

  desc 'Stop TVCal'
  task :stop do
    on roles(:app), in: :sequence, wait: 2 do
      execute "cd #{current_path}; if [ -f #{fetch :pid_path} ] && [ -e /proc/$(cat #{fetch :pid_path}) ]; then kill -9 `cat #{fetch :pid_path}`; rm #{fetch :pid_path}; fi"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence do
      invoke 'deploy:stop'
      invoke 'deploy:start'
    end
  end

  desc 'Precompile Assets'
  task :precompile do
    on roles(:app), in: :sequence do
      execute :rake 'assetpack:build'
    end
  end

  after :publishing, :precompile

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
