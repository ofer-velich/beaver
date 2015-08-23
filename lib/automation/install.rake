require 'erb'
require 'pathname'
namespace :interlude do
	namespace :install do

		desc 'Install sites'
		task :sites => [:evns_exist] do |t,args|
			sites = ENV['SITES_TO_INSTALL'].split(',')
			puts "install_sites #{sites}"

			# create site folder
			sites_dir = Pathname.new('sites')
			mkdir_p sites_dir

			sites.each do |site|

				# continue only if site is not already exist...
				if installed_sites.include? site
					puts "#{site} already install..."
					next
				end

				# create site folder
				site_dir = Pathname.new("sites/#{site}")
				deploy_rb = File.expand_path("../templates/deploy.rb.erb", __FILE__)
				mkdir_p site_dir

				template = File.read(deploy_rb)
				file = site_dir.join('deploy.rb')
				File.open(file, 'w+') do |f|
	  				f.write(ERB.new(template).result(binding))
				end

				generic_envs.each do |env|
					# create site env folder
					env_dir = Pathname.new("sites/#{site}/#{env}")
					config_rb = File.expand_path("../templates/config.rb.erb", __FILE__)
					mkdir_p env_dir
				
					template = File.read(config_rb)
					file = env_dir.join('config.rb')
					File.open(file, 'w+') do |f|
		  				f.write(ERB.new(template).result(binding))
					end
				end

			end
		end

		desc 'Install env'
		task :envs do |t|
			env = ENV['BEAVER_ENV_TO_INSTALL'] || ""
			hostnames_strs = ENV['BEAVER_HOSTNAMES_TO_INSTALL'].split(',') || ""
			hostnames = []

			# create site folder
			deploy_dir = Pathname.new('config/deploy')
			mkdir_p deploy_dir

			hostnames_strs.each do |host|
				hostprams = host.split("@")
				hostname = {}

				if ! hostprams[0].nil?
					hostname["name"] = hostprams[0]
				else
					puts "host name is not defined..."
					exit 1
				end 

				if ! hostprams[1].nil?
					hostname["role"] = hostprams[1]
				end 

				hostnames << hostname
			end
			
			# validate env
			env_exist(env)
			
			env_servers_rb = File.expand_path("../templates/env_servers.rb.erb", __FILE__)
			template = File.read(env_servers_rb)
			file = deploy_dir.join("#{env}.rb")
			File.open(file, 'w+') do |f|
				f.write(ERB.new(template).result(binding))
			end			

		end

		desc 'Install Discovery env'
		task :discovery_env do |t|

			env = ENV['BEAVER_ENV_TO_INSTALL'] || ""
			region = ENV['BEAVER_AWS_REGION'] || ""
			tagname = ENV['BEAVER_AWS_TAG_NAME'] || ""
			tagvalue = ENV['BEAVER_AWS_TAG_VALUE'] || ""

			if region.empty? || tagname.empty? || tagvalue.empty?
				puts "please validate that all AWS config values are defined (access_key,secret_access,region,tagname,tagvalue)"
			end

			# validate env
			env_exist(env)

			# create site folder
			deploy_dir = Pathname.new('config/deploy')
			mkdir_p deploy_dir
			
			env_servers_rb = File.expand_path("../templates/discovery.rb.erb", __FILE__)
			template = File.read(env_servers_rb)
			file = deploy_dir.join("#{env}.rb")
			File.open(file, 'w+') do |f|
				f.write(ERB.new(template).result(binding))
			end			

		end

		desc 'Validate that "env" files have been created'
		task :evns_exist do |t|
			unless ! installed_envs.empty?
				puts "You must configure site's environment before you can configure a site"
				exit 1 
			end
		end


		def installed_sites
			return Dir.entries("sites").delete_if {|site| site == "." || site == ".."}
		end

		def installed_envs
			return Dir.entries("config/deploy").delete_if {|site| site == "." || site == ".."}
		end

		# envs are eider production or sandbox
		def generic_envs
			return ["production", "sandbox"]
		end

		def env_exist(env)
			if env == ""
				puts "can not install empty env...."
				exit 1
			end

			if installed_envs.include? env
				puts "env is already exist...."
				exit 1
			end
		end


		  
	end
end
