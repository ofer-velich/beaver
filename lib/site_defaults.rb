
# Sensible defaults for sites resource
# ====================================

# s3 object name
set :s3object, (fetch(:application)+'.zip')

# where to deploy
set :deploy_to, '~/sites/'+fetch(:application)

if fetch(:env_type) == :sandbox
     set :keep_releases, 2
end
