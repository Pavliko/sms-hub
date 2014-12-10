# Basic settings:
#   domain       - The hostname to SSH to.
#   hostname     - server_name for nginx config.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)

set :app_name, 'sinatra-sample'
set :hostname, 'example.com'
set :domain, 'ssh.example.com'
set :deploy_to, "/var/www/#{app_name}"
set :repository, 'git@github.com:Pavliko/sinatra-sample.git'
