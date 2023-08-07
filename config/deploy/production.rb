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
lock '3.17.3'
set :rails_env, 'production'
set :application, 'hijama'
set :user, "deployer"


# Default value for :scm is :git
set :scm, :git
set :repo_url, 'git@github.com:ziko07/hijamago.git'
set :branch, 'master'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deployer/apps/hizama"

