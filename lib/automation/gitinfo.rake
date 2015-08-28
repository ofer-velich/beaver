require 'json'
require 'uri'
require 'open-uri'

	namespace :gitinfo do

		desc 'Retrieve the latest releases (if exists)of a given branch'
		task :latest_release do |t|
			repo_name = ENV['BEAVER_GITINFO_REPO_NAME'] || ""
			
			if repo_name.empty?
				puts "unknown branch, please make sure you supply the correct repository name via the"
				puts "env variable: BEAVER_GITINFO_REPO_NAME"
				exit 1
			end

			hash = JSON.parse(json)
			
			releases = []
			hotfix = []
			
			hash.each do |branch ,value|
  				if branch.start_with?('release/')
					releases << branch
				end

				if branch.start_with?('hotfix/')
					hotfix << branch
				end
			end

			releases = hotfix.length > 0 ? hotfix : releases


			if releases.length == 1
			 	puts releases.first
			 	exit 0
			end

			if releases.length > 1
				puts "Too many releases"
				exit 1
			end

			puts "No release found"
		end

		desc 'Retrieve the latest varsion of a given branch'
		task :branch_version do |t|
			repo_path = ENV['BEAVER_GITINFO_REPO_PATH'] || ""

			if repo_path.empty?
				puts "unknown branch, please make sure you supply the correct repository path via the"
				puts "env variable: BEAVER_GITINFO_REPO_NAME"
				exit 1
			end
		
			Dir.chdir(repo_path) do
  				
				branch=`git rev-parse --abbrev-ref HEAD`

				if branch.start_with?('release/') || branch.start_with?('hotfix/')
					puts branch.split('/').last
				else
					revision = `git rev-list --tags --max-count=1`
					tag_name = `git describe --tags #{revision}`
					puts tag_name || '0'
				end

  			end

		end

		desc 'Retrieve the branch name, for hotfix/releases branches, retrieve only the branch base name (i.e hotfix/releases)'
		task :branch_base_name do |t|
			repo_path = ENV['BEAVER_GITINFO_REPO_PATH'] || ""

			if repo_path.empty?
				puts "unknown branch, please make sure you supply the correct repository path via the"
				puts "env variable: BEAVER_GITINFO_REPO_NAME"
				exit 1
			end
		
			Dir.chdir(repo_path) do
  				
				branch=`git rev-parse --abbrev-ref HEAD`

				if branch.start_with?('release/')
					puts 'release'
				elsif branch.start_with?('hotfix/')
					puts 'hotfix'
				else
					puts branch || '0'
				end

  			end

		end

		desc 'Retrieve the latest tag (if exists)of a given branch'
		task :latest_tag do |t|
			repo_name = ENV['BEAVER_GITINFO_REPO_NAME'] || ""
			
			if repo_name.empty?
				puts "unknown branch, please make sure you supply the correct repository name via the"
				puts "env variable: BEAVER_GITINFO_REPO_NAME"
				exit 1
			end

			hash = JSON.parse(json)
			tags = hash.keys

			latest='0'

			tags.each do |value|
				if Gem::Version.new(value) > Gem::Version.new(latest) 
					latest = value
				end
			end

			if latest != '0'
				puts latest
				exit 0
			end

			puts "No tags found"
		end
		  
	end
