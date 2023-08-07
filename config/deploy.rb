# config valid only for current version of Capistrano
lock "3.17.3"

set :scm, :git
# set :ssh_options, {
#                     :keys => '/home/nazrul/Desktop/shyftn/shyftn.pem'
#                 }
# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true
server '54.89.225.60',
       :user => 'deployer',
       :roles => %w{web app db}

set :rvm_ruby_version, '3.2.2'

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/secrets.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets public/uploads pdf_files public/cash_pulls public/closed_tills public/invoices}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :assets_prefix, 'pipeline_assets'

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  #before :deploy, "deploy:check_revision"
  #after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after :finishing, 'deploy:cleanup'
  #before 'deploy:setup_config', 'nginx:remove_default_vhost'
  #after 'deploy:setup_config', 'nginx:reload'
  #after 'deploy:setup_config', 'monit:restart'
  #after 'deploy:publishing', 'deploy:restart'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

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

task :upload_secret_files do
  on roles(:all) do |host|
    begin
      execute "mkdir #{shared_path}/config"
    rescue
    end
    upload! "config/application.yml", "#{shared_path}/config/application.yml"
  end
end

desc 'Invoke a rake command on the remote server'
task :invoke, [:command] => 'deploy:set_rails_env' do |task, args|
  on primary(:app) do
    within current_path do
      with :rails_env => fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

