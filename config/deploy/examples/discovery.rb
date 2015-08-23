set :stage, :production

set :env_type, :production

set :region, 'region'

# find all running EC2 servers tagged with Role=worker
instances = AWS::EC2::Client.new.describe_instances(filters: [
              {name: 'tag:Tagname', values: ['somevalue']},
              {name: 'instance-state-name', values: ['running']}
            ])

instances.instance_index.values.each do |host|
	# Extended Server Syntax
	# ======================
	# This can be used to drop a more detailed server
	# definition into the server list. The second argument
	# something that quacks like a hash can be used to set
	# extended properties on the server.
	server host[:dns_name], user: 'ubuntu', roles: %w{web app}
end


# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
set :ssh_options, {
	keys: %w(/home/rlisowski/.ssh/id_rsa),
	forward_agent: false,
	auth_methods: %w(password)
}