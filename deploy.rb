
# Default values (ruby/gems/1.9.1/gems/capistrano-3.0.1/lib/capistrano/default.rb)
# ==================================================================================

# set :tmp_dir, "/tmp"
# set :format, :pretty
# set :log_level, :debug
# set :default_env, {}
set :keep_releases, 3
# set :pty, false


# Default values (lib/default.rb)
# ==================================================================================

# set :scm, :s3
# set :sites, Dir.entries("sites")
# set :scripts_folder, '~/update'
# set :s3bucket, ''
# set :s3object, ''


# Default Deployment flow
# ========================
# deploy:starting    - start a deployment, make sure everything is ready
# deploy:started     - started hook (for custom tasks)
# deploy:updating    - update server(s) with a new release
# deploy:updated     - updated hook
# deploy:publishing  - publish the new release
# deploy:published   - published hook
# deploy:finishing   - finish the deployment, clean up everything
# deploy:finished    - finished hook


# Default Rollback flow
# ========================
# deploy:starting
# deploy:started
# deploy:reverting           - revert server(s) to previous release
# deploy:reverted            - reverted hook
# deploy:publishing
# deploy:published
# deploy:finishing_rollback  - finish the rollback, clean up everything
# deploy:finished


# Load Site Task
# ==========================

namespace :load do
    task :site, :sitename do |t, args|
        set :sitename, args[:sitename]
        if File.file?("lib/capistrano/tasks/sites/#{fetch(:sitename)}.rake")
            load "lib/capistrano/tasks/sites/#{fetch(:sitename)}.rake"
        end
        load "sites/#{fetch(:sitename)}/deploy.rb"
        load "sites/#{fetch(:sitename)}/#{fetch(:env_type)}/config.rb"
    end
end

# Site Tasks (task for every site name)
# =======================================

fetch(:sites).each do |site|
    Rake::Task.define_task(site) do
        invoke 'load:site', site
        invoke 'deploy'
    end
end


# Rollback Site Tasks (task for every site name)
# =======================================

fetch(:sites).each do |site|
    Rake::Task.define_task("#{site}:rollback") do
        invoke 'load:site', site
        invoke 'deploy:rollback'
    end
end



# Run generic tasks...

# "Run" Site Tasks (task for every site name)
# =======================================

fetch(:sites).each do |site|
    Rake::Task.define_task("#{site}:run") do
        invoke 'load:site', site

        task = ENV['BEAVER_TASK']
        params = ENV['BEAVER_TASK_PARAMS']

        if (params.to_s.empty?)
            invoke task
        else
            arr_arg = params.split(",")
            Rake::Task["#{task}"].invoke(*arr_arg)
        end

    end
end


# "Run" Tasks
# =======================================

Rake::Task.define_task("run") do
    task = ENV['BEAVER_TASK']
    params = ENV['BEAVER_TASK_PARAMS']

    if (params.to_s.empty?)
        invoke task
    else
        arr_arg = params.split(",")
        Rake::Task["#{task}"].invoke(*arr_arg)
    end
end



# Deploy Tasks
# ==========================

namespace :deploy do

    # First thing, we need to ensure that the deploy to folder exist and writable
    before 'starting', 'mysite:ensure_deploy_to'

    task :restart do
        # Stub that must be implemented
    end

    # Run updates(e.i change permissions) on the current_path, when leaving the release into a new current_path.
    task :finishing => 'mysite:ensure_cleanup'
  
end

