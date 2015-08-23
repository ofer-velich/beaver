
# Sensible defaults for sites tasks
# ====================================

# set source control management system
set :scm, ENV["BEAVER_SCM"].to_sym

# s3 defaults
set :s3bucket, "path.to.bucket"
set :s3syncFlags, "--delete-removed"


set :chown_dirs, []
set :chmod_dirs, []
set :clean_dirs, []
set :webserver_user, 'www-data'
set :server_type, 'apache'

# array contains all configured sites
set :sites, Dir.entries("sites")
fetch(:sites).delete_if {|site| site == "." || site == ".."}

# remote machine update scripts directory
set :scripts_folder, '~/update'

# aws defaults
set :aws_access_key, (ENV["BEAVER_AWS_ACCESS_KEY"] ? ENV["BEAVER_AWS_ACCESS_KEY"] : ENV["AWS_ACCESS_KEY_ID"]) 
set :aws_secret_access_key, (ENV["BEAVER_AWS_SECRET_KEY"] ? ENV["BEAVER_AWS_SECRET_KEY"] : ENV["AWS_SECRET_ACCESS_KEY"])


set :region, (ENV["BEAVER_AWS_REGION"] ? ENV["BEAVER_AWS_REGION"] : 'us-east-1')

# remote machine maintenance script
def maintenance_script
	return "#{fetch(:scripts_folder)}/maintenance.sh"
end

# remote machine update script
def update_script
	return "#{fetch(:scripts_folder)}/sites/#{fetch(:application)}/update.sh"
end

# path to bamboo artifact
def s3_object_path
	if ENV["BEAVER_S3_OBJECT_PATH"] != ''
		return ENV["BEAVER_S3_OBJECT_PATH"]
	end
	
	return fetch(:s3object)
end

def sites_available_path
	return "/etc/apache2/sites-available"	
end

def sites_enabled_path
	return "/etc/apache2/sites-enabled"	
end

def virtual_host_path
	return "#{current_path}/deploy/#{fetch(:env_type)}/#{virtual_host}"	
end

def logs_virtual_host_path
	return "#{current_path}/deploy/#{fetch(:env_type)}/log.mysite.com.conf"	
end

def virtual_host
    return "#{fetch(:virtual_host_override, fetch(:application))}.conf"
end

def logstash_forwarder_conf_path
	return "/etc/logstash-forwarder"	
end

def logstash_forwarder_conf_template_path
	return "/home/ubuntu/install/config/logs/logstash/shipper/logstash-forwarder.conf"	
end

def site_log_files_path
	return "#{current_path}/deploy/#{fetch(:env_type)}/log_files.json"	
end

