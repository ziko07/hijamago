# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}
#
#
# config valid only for current version of Capistrano
lock '3.4.0'
set :rails_env, 'production'
set :application, 'hijama'
set :user, "deployer"


# Default value for :scm is :git
set :scm, :git
set :repo_url, 'git@bitbucket.org:tracdev/cgms-v2.git'
set :branch, 'eprocure'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deployer/apps/hizama"

# Default value for :pty is false
set :pty, true


server '54.89.225.60', user: 'deployer', roles: %w{web app db}, primary: true



# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

role :app, %w{deployer@54.89.225.60}#, my_property: :my_value
role :web, %w{deployer@54.89.225.60}#, other_property: :other_value
role :db,  %w{deployer@54.89.225.60}



# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#   set :ssh_options, {
#     keys:%w(/home/root/.ssh/id_rsa),
#     forward_agent: true,
#     auth_methods: %w(password),
#     password: 'CGMS@2014'
#   }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
