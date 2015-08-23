def dir_exists?(path)
    return exists?('d', path)
end

def symlink_exists?(path)
    return exists?('L', path)
end

def file_exists?(path)
    return exists?('f', path)
end

def files_exist?(regexp)
    res = capture("stat -t #{regexp} >/dev/null 2>&1 && echo \"file exists\" || echo \"file doesn\'t exist\"")
    res = res.strip
    
    return res === "file exists"
end

def file_executable?(path)
    return exists?('f', path) && exists?('x', path)
end

def exists?(type, path)
	exists = test("[ -#{type} #{path} ]")

    if exists
    	info "Found #{path}"
    else
    	info "Can not find #{path}"
    end
    
    return exists
end

def run_script(command)
    info "Running script #{command}"
	execute command
end

def create_dir(path)
	execute :mkdir, "-p", path
    info "Directory created in: #{path}"
end

def delete_dir(path)
	execute :sudo, :rm, "-fr", path
    info "Directory removed from: #{path}" 
end

def create_symlink(from, to, delete_existing=false, sudo=false )
    if delete_existing && symlink_exists?(to)
        delete_file(to)
    end
    
    if sudo
        execute :sudo, :ln, "-s", from, to
    else
        execute :ln, "-s", from, to
    end

    info "Symlink created from: #{from} to: #{to}"
end

def create_file(path, content = "")
    execute "sudo echo #{content} > #{path}"
    info "created file: #{path}"
end

def upload_file(path, content)
    if is_run_locally?
        File.open(path,"w") do |f|
  	    f.write(content)
	end
    else
        upload! StringIO.new(content), path        
    end
    
    info "file uploaded to: #{path}"
end

def copy_file(from, to)
	execute :sudo, :cp, from, to
    info "copy file: from: #{from} to: #{to}"
end

def delete_file(path)
	execute :sudo, :rm, path
    info "File removed from: #{path}" 
end

def change_permissions(path, permissions, recursive=false)
	recursive = recursive == true ? "-R" : ""
    execute :sudo, :chmod, recursive, permissions, path
	info "Updated permissions #{permissions} for #{path}"	
end

def change_owner(path, user, recursive=false)
	recursive = recursive == true ? "-R" : ""
	execute :sudo, :chown, recursive, user, path
	info "Updated owner #{user} for #{path}"	
end

def sed_replace(regexp, replacement, path)
    if file_exists?(path)
        info "Replacing: #{regexp} ... With: #{replacement} on #{path}" 
        execute :sudo, :sed, "-i", "\"s|#{regexp}|#{replacement}|\"", path
        return 0
    else
        # if file not exits return fail status 
        info "Failed Replacing: cant find path: #{path}"
        return 1
    end
end


def create_site_available(vhost_path, vhost)
    if file_exists?(vhost_path)
        if file_exists?("#{sites_available_path}/#{vhost}") || symlink_exists?("#{sites_available_path}/#{vhost}")
            delete_file("#{sites_available_path}/#{vhost}")
        end
        
        create_symlink(vhost_path, "#{sites_available_path}/#{vhost}", false, true)            
    end
end

def is_site_enabled?(site)
    info "check if #{site} enabled ..."

    return symlink_exists?("#{sites_enabled_path}/#{site}.conf")
end

def create_site_enabled(site)
    info "Enabling site: #{site}..."

    if file_exists?("#{sites_available_path}/#{site}.conf") || symlink_exists?("#{sites_available_path}/#{site}.conf")
        execute :sudo, :a2ensite, "#{site}.conf"
    end
end

def restart_logstash()
    if fetch(:env_type) == :production
        info "Executing logstash Restart."
        execute "sudo service logstash-forwarder restart"
    end
end

def restart_apache2()
    info "Executing graceful apache Restart."
    execute "sudo /etc/init.d/apache2 graceful > /dev/null"
end

def is_node_running?()
    info "check if node is running"
    begin
        execute "pgrep nodejs"
        info "node is running"
        return true
    rescue
        info "node is not running"
        return false
    end
end

def restart_node(executable)
    info "Executing node Restart."

    #options = "-o out.log -e err.log"
    options=""
    begin
        execute "NODE_PATH=/usr/lib/nodejs:/usr/lib/node_modules NODE_ENV=#{fetch(:env_type)} forever restart #{options} #{executable}"
    rescue
        execute "NODE_PATH=/usr/lib/nodejs:/usr/lib/node_modules NODE_ENV=#{fetch(:env_type)} forever start #{options} #{executable}"  
    end    
end

def start_node(executable)
    info "Executing node start."
    options=""
    execute "NODE_PATH=/usr/lib/nodejs:/usr/lib/node_modules NODE_ENV=#{fetch(:env_type)} forever start #{options} #{executable}"  
end

def ubuntu_var()
    output = capture("lsb_release -a | awk '{print $2}'").split
    return output.last
end


