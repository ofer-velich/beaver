# application name
set :application, 'myaap.com'

load 'lib/site_defaults.rb'

# setup vars
set :chown_dirs, ["storage"]
set :clean_dirs, ["storage/views/*","storage/cache/*","storage/logs/*"]


# Deploy Tasks
# ==========================

namespace :deploy do
  
  # After the site code has been updated try to relink the virtual host file from the deploy folder
  task :restart do
    invoke 'ensure_virtual_host'
  end

  # After the site code has been updated try to run updates on the current release
  task :published do
    invoke 'admin:update_paths'
    invoke 'public_symlink'
    invoke 'chown'
    invoke 'clear_cache'
  end

  task :finished do
    invoke 'ensure_site_enabled', fetch(:sitename)
  end  
  
end

