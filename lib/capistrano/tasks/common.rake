namespace :mysite do

	desc "Check that we can access everything into deploy to folder"
	task :ensure_deploy_to do
		on_hosts roles(:all) do |host|

			if !dir_exists?(fetch(:deploy_to))
				create_dir(fetch(:deploy_to))
			end

			change_permissions("#{fetch(:deploy_to)}/", "+w")
		end
	end

    desc "Check if the configured hosts are of the same type to a given variable"
    task :env_type, :env do |t, args|
		env = args[:env]
  
		if fetch(:env_type) == env.to_sym
			exit 0
		end

        exit 1
    end

	desc "Change ownership to all directories and files listed under the chown_dirs to be owned by the configured web server user"
	task :chown do
		on_hosts roles(:all) do |host|
			info "Change ownership to #{fetch(:chown_dirs)}, to be owned by #{fetch(:webserver_user)}"		
			
			fetch(:chown_dirs).each do |dir|
				path = "#{release_path}/#{dir}"
				if dir_exists?(path)
					change_owner("#{path}", fetch(:webserver_user), true)
				else
					info "can not change owner, #{path} does not exists... "
				end
			end   
		end
	end


	desc "Change permissions to all directories and files listed under the chmod_dirs"
	task :chmod, :permissions do |t, args|
		on_hosts roles(:all) do |host|

			permissions = args[:permissions]

			info "Change ownership to #{fetch(:chmod_dirs)}, to be owned by #{permissions}"		
			
			fetch(:chmod_dirs).each do |dir|
				path = "#{release_path}/#{dir}"
				if dir_exists?(path)
					change_permissions(path, permissions, true)
				else
					info "can not change permissions, #{path} does not exists... "
				end
			end   
		end
	end

	desc "Celar all directories listed under the clean_dirs"
	task :clear_cache do
		on_hosts roles(:all) do |host|
			info "Running clear cache on #{fetch(:clean_dirs)}"		

			fetch(:clean_dirs).each do |dir|
				path = "#{release_path}/#{dir}"
				if dir_exists?(path)
					delete_dir(path)
				else
					info "can not clear cache, #{path} does not exists... "
				end
			end

		end
	end

	desc "Create a public symlink to the dist dir"
	task :public_symlink do
		on_hosts roles(:all) do |host|
			info "Running create public symlink"		

			public_dir = "#{current_path}/public"
			dist_dir = "#{current_path}/public.dist"

			if dir_exists?(dist_dir) && ! dir_exists?(public_dir) && ! symlink_exists?(public_dir)
				create_symlink(dist_dir, public_dir)
			end

		end
	end


	desc "Update logrotate content"
	task :logrotate, :logrotate_path, :logrotate_upstart do |t, args|
		on_hosts roles(:all) do |host|
			logrotate = args[:logrotate_path]
			logrotate_upstart = args[:logrotate_upstart]

			copy_file(logrotate, '/etc/logrotate.d/')
			copy_file(logrotate_upstart, '/etc/init/')
		end
	end

	desc "Configure cron job using a configuration file"
	task :crontab, :file, :machine_type do |t, args|
		on_hosts roles(:all) do |host|

			file = args[:file]
			machine_type = args[:machine_type]

			if (defined?(file)).nil?
				error "file param must be defined\n"
				exit 1
			end

			if (defined?(machine_type)).nil?
				error "machine_type param must be defined\n"
				exit 1
			end

			if !symlink_exists?(file) && !file_exists?(file)
				info "Cron job configuration file dose not exist..."
				exit 1		
			end
			
			default_cron_file_path = "/home/ubuntu/install/config/ubuntu/#{ubuntu_var()}/cron/#{fetch(:env_type)}/#{machine_type}.cron"
			default_cron_file_content = ""

			if file_exists?(default_cron_file_path)
				default_cron_file_content = capture(:cat, default_cron_file_path)
			end

			temp_file_path = "/home/ubuntu/temp_beaver_crontab_file"
			file_content = capture(:cat, file)
			concatinated_content=nil

			if default_cron_file_content.empty?
				info "Configuring new crontab..."
				
				concatinated_content = "#{file_content}\n"
			else
				info "Adding configuration to existing crontab..."
	
				concatinated_content = "#{default_cron_file_content}\n#{file_content}\n"
			end

			# upload to temp path
        	upload_file(temp_file_path, concatinated_content)

			execute :crontab, temp_file_path

			execute :rm, temp_file_path
		end
	end

	desc 'Update the current_path, when leaving the release into a new current_path'
	task :ensure_cleanup do
		on_hosts roles :all do |host|

			releases = capture(:ls, '-x', releases_path).split
			last_releases_are = releases - [releases.last]

			if last_releases_are.any?

				last_releases_are.each do |release|
					full_path = releases_path.join(release)
					execute "sudo chown -R :ubuntu #{full_path}"
					execute "sudo chmod -R g+w #{full_path}"
				end
			end
		end
	end

	desc 'Move site on/off to maintenance mode'
	task :maintenance, [:state] do |t, args|
	  	on_hosts roles(:all) do |host|
	  		state = args[:state] == 'on' ? 'disable' : (args[:state] == 'off' ? 'enable' : nil)
	  		puts "the maintenance sites are #{args.extras}"
			sites = args.extras.map { |site| "-s " + site }.join(' ')

			if (defined?(state)).nil?
				puts 'make sure you add the correct mode(on/off) when calling to the task'
				exit 1
			end

			mode = "-m " + state

			unless file_executable?(maintenance_script)
			  	error "Fail to find maintenance.sh, File have not been found or it is not executable" 
			end

  			info "Running maintenance #{state}, for sites #{sites}..."		

			run_script("#{maintenance_script} #{mode} #{sites}")
  		end
	end

	desc "Check that we can access everything into deploy to folder"
	task :ensure_virtual_host do
		on_hosts roles(:all) do |host|
			create_site_available(virtual_host_path, virtual_host)
		end
	end

	desc 'Enable an apache site'
	task :ensure_site_enabled, :site do |t, args|
	  	on_hosts roles(:all) do |host|
			maintenance_flag = is_site_enabled?('000-maintenance.mysite.com')
			site = args[:site]

			if maintenance_flag
			  puts "maintenance_flag is on, wait till all sites are deployed!"
			else
				create_site_enabled(site)
			end
  		end
	end

	desc "Server Restart."
	task :restart_server do
		on_hosts roles(:all) do |host|

			if fetch(:server_type) == "apache"
				info "Executing Server Restart."
				restart_apache2()
			end

		end
	end

	desc "Refresh servers running on a auto scale group"
	task :refresh_auto_scale_group, :group_name do |t, args|

		group_name = args[:group_name]
		
		client = create_autoscale_client()

		group_description = describe_auto_scaling_group(group_name)
		
		# list all currently existing servers in the auto scale group
		instances = group_description.instances
		
		puts "we have currently #{instances.size} instances running in the #{group_name} group"

		# double the auto scale group 
		desired_capacity = group_description.desired_capacity * 2
		
		puts "update auto scale group with a new capcity #{desired_capacity}"

		client.update_auto_scaling_group(
			auto_scaling_group_name: group_name,
			min_size: desired_capacity,
			max_size: desired_capacity,
			desired_capacity: desired_capacity
		)

		# wait till the adjustment completes
		while describe_auto_scaling_group_running_instances(group_name).size < desired_capacity
            puts "instances are been created, please wait..."
            sleep 1
        end

		puts "update auto scale group to the previous min size #{group_description.min_size}"

        client.update_auto_scaling_group(
			auto_scaling_group_name: group_name,
			min_size: group_description.min_size
		)

		# close all of the "old" servers, and let them to restart
		instances.each do |instance|

			puts "terminate instance #{instance.instance_id} in #{group_name} auto scale group"

			client.terminate_instance_in_auto_scaling_group(
				# required
				instance_id: instance.instance_id,
				# required
				should_decrement_desired_capacity: true
			)
	    end

		# reset the auto scale group with all of the previous values
        client.update_auto_scaling_group(
			auto_scaling_group_name: group_name,
			min_size: group_description.min_size,
			max_size: group_description.max_size
		)
	end

	desc "Update machine environment scripts"
	task :update_machine_env do
		on_hosts roles(:all) do |host|
			within '/home/ubuntu/install/scripts/setup' do
				run_script('./setup_env.sh')
			end
		end		
	end


end
