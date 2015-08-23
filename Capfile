# Load DSL and Setup Up Stages
include Capistrano::DSL

namespace :load do
  task :defaults do
    load 'capistrano/defaults.rb'
    load 'lib/defaults.rb'
    load 'lib/bash_utils.rb'
    load 'lib/aws_utils.rb'
    load 'lib/dsl.rb'
  end
end

stages.each do |stage|
  Rake::Task.define_task(stage) do
    invoke 'load:defaults'
    load 'deploy.rb'
    load "config/deploy/#{stage}.rb"
    load "lib/capistrano/tasks/scm/#{fetch(:scm)}.rake"
    set(:stage, stage.to_sym)
    I18n.locale = fetch(:locale, :en)
    configure_backend
  end
end

require 'capistrano/dotfile'

local = ENV["BEAVER_LOCAL"] || false
if local != false

  # Includes local deployment tasks
  load 'lib/local/tasks/framework.rake'
  load 'lib/local/tasks/deploy.rake'

else

  # Includes default deployment tasks
  require 'capistrano/deploy'

end

I18n.enforce_available_locales = false

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
