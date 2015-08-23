#!/usr/bin/env ruby

require 'set'
require 'optparse'
require 'rake'

class BeaverRunner

	attr_reader :version, :print_disclaimers, :sites_list, :envs_list, :action_list, :scms_list, :scm
	attr_accessor :options, :maintenance_list
	
	def initialize()
		@options = {}
		@version = "1.0.3.001"
		@sites_list = Dir.entries("sites").sort().delete_if {|site| site == "." || site == ".."}
		@envs_list = Dir.glob('config/deploy/*.rb').sort().map { |env| File.basename(env, '.*') }
		@maintenance_list = []
		@scms_list = ["s3","bamboo"]
		@action_list = ["deploy", "rollback", "mysite:maintenance", "mysite:api:restore_db", "mysite:api:delete_db", "mysite:env_type", "mysite:update_machine_env", "mysite:refresh_auto_scale_group", "mysite:cms:setup_db"]
		@hosts = []
		@aws_config = {}
		@scm = @scms_list[0]
		@maintenance_flag = false
		@print_disclaimers = true
  	end

  	def parse(args=[])
  		opt_parser = OptionParser.new do |opt|
			opt.banner = "\nUsage: beaver.rb  -e ENVIRONMENT [-a ACTION] [-p PARAMS] [-s SITES ] [-m SITES] [-L]"
			opt.separator  ""
			opt.separator  "Examples"
			opt.separator  "     beaver.rb  -a deploy -e sandbox -s mysite.com"
			opt.separator  "     beaver.rb  -a deploy -e sandbox -s mysite.com -m All"
			opt.separator  "     beaver.rb  -a rollback -e qa -s mysite.com"
			opt.separator  ""
			opt.separator  "Options"

		  	opt.on("-a","--action [ACTION]",list_all("action","\n 					")) do |action|
				@options[:action] = action
		  	end

		  	opt.on("-p","--params [PARAMS]", "Optional params (if needed)") do |params|
				@options[:params] = params
		  	end

			opt.on("-e","--environment ENVIRONMENT",list_all("envs","\n 					")) do |environment|
		    	@options[:env] = environment
			end

			opt.on("-s","--sites site1,site2,site3", Array, list_all("sites","\n 					")) do |sites|
			    @options[:sites] = sites.uniq
			end

			opt.on("-d","--disclaimers [TRUE]", "Override the default value of print_disclaimers if neede") do |value|
			    @print_disclaimers = value
			end

			opt.on("-m","--maintenance-sites site1,site2,site3", Array, "Override maintenance sites, Possible values:", "Array - Override the the maintenance sites with the given sites", "All - Includes all", "None - Exclude all") do |m_sites|
				if m_sites[0] == 'None'
					@maintenance_list =[]
				elsif m_sites[0] == 'All'
					@maintenance_flag = true
					@maintenance_list = @sites_list
				elsif subset?(m_sites, @sites_list)
					@maintenance_flag = true
					@maintenance_list = m_sites
				else
					puts "One or more of the given maintenance sites, did not match to the available sites"
			    	puts opt_parser
		    		exit 1
				end
			end

		  	opt.on("-L","--configure-logs", "Deprecated. Configure the sites log files with the logstash demon") do
				# not in use, the option will be removed.
		  	end

		  	opt.on("-S","--scm SCM", "Sets source control management system, "+list_all("scms","\n 					")) do |scm|
				@scm = scm
		  	end

			opt.on("--s3object", "--s3object path/to/objec", "Path to on object under s3 bucket") do |s3object|
			    @options[:s3object] = s3object
			end

			opt.on("--accesskey", "--accesskey AWS_ACCESS_KEY", "Optional, AWS config access key") do |key|
			    ENV['BEAVER_AWS_ACCESS_KEY'] = key
			end
			
			opt.on("--secretaccess", "--secretaccess AWS_SECRET_ACCESS_KEY", "Optional, AWS config secret access key") do |secret|
				ENV['BEAVER_AWS_SECRET_KEY'] = secret
			end

			opt.on("--region", "--region AWS_REGION","Optional, AWS config region") do |reg|
				ENV['BEAVER_AWS_REGION'] = reg
			end

			opt.on("--awsfilters","--awsfilters key,value", Array, "Optional, AWS tags, ordered in key,value pairs") do |tags|
			    if tags.empty? || tags[0].nil? || tags[1].nil? || tags.length > 2
			    	puts "invalid tags input"
			    	exit 1
			    end

				ENV['BEAVER_AWS_TAG_NAME']= tags[0]
				ENV['BEAVER_AWS_TAG_VALUE'] = tags[1]
			end

			opt.on("-c","--configure-sites site1,site2,site3", Array, "List all sites you wish to install") do |sites|
			    configure_sites(sites.uniq)
			    exit 0
			end

			opt.on("-v","--version","Version") do
		    	puts "version: "+@version
		    	exit 0
			end

		  	opt.on("-l","--list TYPE","List the requested type[envs|actions|sites|maintenance|scms]") do |type|
		  		puts list_all(type,"\n", false)
				exit 0
		  	end
			
			opt.on("-h","--help","Help") do
		    	puts opt_parser
		    	exit 0
			end

		end

		if args.empty?
			return opt_parser
		end

		# parse args
		opt_parser.parse!

		return @options
  	end

  	def list_all(type, separator,indent=true)
  		indent = indent ? "\n 					" : "\n"
		if (instance_variable_defined?("@#{type}_list"))
			list = instance_variable_get("@#{type}_list")
			return "Supported #{type}:#{indent}#{list.join(separator)}" 		
		else
			puts parse()
		end
  	end

	# Validate that the given sites are valid
	def validate_action?(action)
		res = subset?([action], @action_list)
		if ! res
			puts "Action #{action}, is not valid"
		end

	    return res
	end

	# Validate that the given sites are valid
	def validate_sites?()
		res = subset?(@options[:sites], @sites_list)
		if ! res
			puts "Sites, are not valid"
		end

	    return res	
	end

	# Validate that the given envs are valid
	def validate_envs?()
		env = @options[:env]

		res = subset?([env], @envs_list)
		if ! res
			puts "Environment #{env}, is not valid"
		end

	    return res	
	end

	def maintenance?()
		return @maintenance_flag
	end

	# Validate that arr is subset of valid arr
	def subset?(arr, valid_arr)
		valid_set = Set.new valid_arr
		set = Set.new arr
		return set.subset?(valid_set)
	end

	def configure_sites(sites)
		sites = sites.join(",")
		system("rake mysite:install:sites SITES_TO_INSTALL=#{sites}")
	end

	# Run and manage deployment flow
	def deploy(sites, env, action="deploy")
		# Detect if we need to go into maintenance mode
		maintenance_flag = maintenance?()

		if maintenance_flag
			validate_execution(maintenance('on', @maintenance_list, env))
		end

		#Deploy...
		sites.each do |site| 
			validate_execution(cap_deploy(site, env, maintenance_flag, action))
	    end

	    # Go out from maintenance if needed
		if maintenance_flag
			validate_execution(maintenance('off', @maintenance_list, env))
		end

	end


	# Run the cap command on a site
	def cap_deploy(site, env, maintenance_flag, action="deploy")
		if action == "deploy"
			s3object = @options[:s3object] || ""
			print_disclaimer("call cap #{env} #{site}")
			system "cap #{env} #{site} BEAVER_S3_OBJECT_PATH=#{s3object}"
		elsif action == "rollback"
			print_disclaimer("call cap #{env} #{site}:#{action}")
			system "cap #{env} #{site}:#{action}"
		end
	end

	# Run the cap command [on a site]
	def run(sites, env, task, task_params="")
		if sites.empty?
			validate_execution(run_cap("", env, task, task_params))
			return
		end

		sites.each do |site| 
			validate_execution(run_cap(site, env, task, task_params))
	    end
	end

	# Run the cap command
	def run_cap(site, env, task, task_params="") 
		if site == ""
			print_disclaimer("call cap #{env} run BEAVER_TASK=#{task} BEAVER_TASK_PARAMS=#{task_params}")
			system "cap #{env} run BEAVER_TASK=#{task} BEAVER_TASK_PARAMS=#{task_params}" 
		else
			print_disclaimer("call cap #{env} #{site}:run BEAVER_TASK=#{task} BEAVER_TASK_PARAMS=#{task_params}")
			system "cap #{env} #{site}:run BEAVER_TASK=#{task} BEAVER_TASK_PARAMS=#{task_params}"
		end
	end

	# Run the maintenance command
	def maintenance(mode, sites, env)
		run_cap("", env, "mysite:maintenance", "#{mode},#{sites.join(',')}")
	end

	# validate command execution 
	def validate_execution(res)
		unless res
			exit 1 	
		end 
	end

	def print_disclaimer(text)
		if @print_disclaimers == true || @print_disclaimers == "true"
			puts "\n\n===============================================================================================\n\n"
			puts "call #{text}"
			puts "\n===============================================================================================\n\n"
		end
	end
	
end

#####  Run scripts #####

# parse args
b = BeaverRunner.new
b.parse(ARGV)


action = b.options[:action] || "deploy"
sites = b.options[:sites]
env = b.options[:env]
if env.nil?
	# call usage
	puts b.parse()
	exit 1
end

# set environment variables
ENV["BEAVER_SCM"] = b.scm

if env.include? "local"
	ENV["BEAVER_LOCAL"] = "true"
end



# validate and call run 
if (action == "deploy" || action == "rollback")

	if b.validate_sites?() && b.validate_envs?()
		# run deploy or deploy:rollback
		b.deploy(sites, env, action)

		# restart server
		b.run(sites, env, "mysite:restart_server")

		exit 0
	end

# special case for maintenance call
elsif b.validate_envs?() && action == 'mysite:maintenance'
	
	b.maintenance(b.options[:params] || "off", b.maintenance_list, env)

	exit 0

# catch all
elsif b.validate_envs?() && b.validate_action?(action)
	# ensure we have a valid array of sites (or empty)
	sites = !sites.nil? && b.validate_sites?() ? sites : []
	
	# ensure params
	params = b.options[:params] || ""
	
	# run it..
	b.run(sites, env, "#{action}", "#{params}")
	
	exit 0
end

# call usage
puts b.parse()
exit 1
