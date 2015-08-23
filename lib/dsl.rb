require 'sshkit'

module SSHKit

  module DSL

    def on_hosts(hosts, options={}, &block)
		if is_run_locally?
      		run_locally(&block)
		else
			on(hosts, options, &block)
		end 
    end

	def is_run_locally?
		ENV["BEAVER_LOCAL"] ? true : false
	end

  end

end

def required_variable(var, varname)
	
	if (defined?(var)).nil?
		error "#{varname} param must be defined\n"
		exit 1
	end
	
end
