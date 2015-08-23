set :stage, :sandbox

set :env_type, :sandbox

server '127.0.0.1', user: 'ubuntu', roles: %w{web app db} # local

set :log_level, :debug