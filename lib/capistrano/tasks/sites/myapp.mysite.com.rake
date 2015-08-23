namespace :mysite do

	namespace :myapp do
		
		desc "Updates on hard coded paths, on the current release"
		task :update_paths do
			on_hosts roles(:all) do |host|
				if fetch(:env_type) == :sandbox
					sed_replace('AWS_EC2_HOSTNAME', ec2_public_hostname, "#{current_path}/example.php")			
				end				
			end
		end
		
	end

end
