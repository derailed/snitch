load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy' 

# Load multistage
require 'capistrano/ext/multistage'
           
set :application , "snitch"
set :stages      , %w[staging production]
set :keep_release, 5                
set :svn_root    , 'http://mole.rubyforge.org/svn/mole/snitch'

# -----------------------------------------------------------------------------
# !!!! Please change for your deployment landscape !!!!

# Specify your remote deployment directory
set :deploy_to         , File.join( 'change_me_deployment_dir', application )
# Specify your deployment user
set :user              , 'change_me_deployment_user'
# Specify your staging and production hosts
set :production_biscuit, "change_me_prod_box"
set :staging_biscuit   , "change_me_staging_box"
