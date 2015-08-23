set :stage, :production

set :env_type, :production

server '127.0.0.1', user: 'ubuntu', roles: %w{web app} # local

set :log_level, :debug