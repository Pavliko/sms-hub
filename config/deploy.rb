require 'mina/bundler'
require 'mina/git'
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'mina/unicorn'
require './config/deploy_config' if File.exists? 'config/deploy_config.rb'

# Basic settings:
#   branch       - Branch name to deploy. (needed by mina/git)
#   hostname     - server_name for nginx config.
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
set_default :app_name, 'sinatra-sample'
set_default :hostname, 'example.com'
set_default :domain, 'ssh.example.com'
set_default :deploy_to, "/var/www/#{app_name}"
set_default :repository, 'git@github.com:Pavliko/sinatra-sample.git'
set :branch, 'master'

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/settings.yml', 'config/unicorn.rb', 'config/nginx.conf', 'config/monit.conf', 'log', 'tmp']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[ruby-2.1@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/sockets"]

  # queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  # queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]

  deploy do
    invoke :'git:clone'
    # invoke :'deploy:cleanup'
  end

  invoke :'sync_unicorn'
  invoke :'sync_nginx'
  invoke :'sync_monit'
  invoke :'sync_settings'
end

task :setup_finish => :environment do
  queue %{ echo '
    -----HOW TO NEXT-----
    Your project placed in:
    #{deploy_to}

    Insert in your nginx.conf next line:
    include #{deploy_to}/#{shared_path}/config/nginx.conf;

    And restart Nginx.
  '}
end

def sed search, replacement, file
  queue! %[sed 's/%%{#{search}}/#{replacement.gsub("/","\\\/")}/g' #{file} > #{file}.tmp]
  queue! %[mv -f #{file}.tmp #{file}]
end

def replace_defaults path
  sed(:deploy_to, deploy_to, path)
  sed(:current_path, current_path, path)
  sed(:shared_path, shared_path, path)
  sed(:app_name, app_name, path)
  sed(:hostname, hostname, path)
end

task :sync_unicorn => :environment do
  config_path = "#{deploy_to}/#{shared_path}/config/unicorn.rb"
  queue! %[cp "#{deploy_to}/#{current_path}/config/unicorn.example.rb" "#{config_path}"]
  replace_defaults(config_path)
end

task :sync_nginx => :environment do
  config_path = "#{deploy_to}/#{shared_path}/config/nginx.conf"
  queue! %[cp "#{deploy_to}/#{current_path}/config/nginx.example.conf" "#{config_path}"]
  replace_defaults(config_path)
end

task :sync_monit => :environment do
  config_path = "#{deploy_to}/#{shared_path}/config/monit.conf"
  queue! %[cp "#{deploy_to}/#{current_path}/config/monit.example.conf" "#{config_path}"]
  replace_defaults(config_path)
end

task :sync_settings => :environment do
  config_path = "#{deploy_to}/#{shared_path}/config/settings.yml"
  queue! %[cp "#{deploy_to}/#{current_path}/config/settings.example.yml" "#{config_path}"]
  sed(:slack_webhook, slack_webhook, config_path)
end


desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'unicorn:restart'
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
