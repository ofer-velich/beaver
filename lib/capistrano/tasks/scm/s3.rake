namespace :s3 do
  
desc 'Check that the bucket is reachable'
  task :check do
    on_hosts roles :all do
      s3url = "s3://#{fetch(:s3bucket)}/"
      info "Checking that the bucket is reachable..., from #{s3url}"
    end
  end

  desc 'Sync changes from the remote bucket'
  task :create_release do
    on_hosts roles :all do
      
      if !dir_exists?(repo_path)
        create_dir(repo_path)
        change_permissions(repo_path, "+w", true)
      end

      info "Creating new release directory path"    
      execute :mkdir, '-p', release_path
      
      s3url = "s3://#{fetch(:s3bucket)}/#{s3_object_path}"
      info "Running s3cmd get..., from #{s3url} into #{release_path}"    
      execute "s3cmd get #{s3url} #{release_path}/#{s3_object_path} > /dev/null"

      info "Extract into the new release path"        
      execute :unzip, "#{release_path}/#{s3_object_path}", "-d", "#{release_path}", "> /dev/null"

      info "Remove the #{s3_object_path} from release path"    
      execute :rm, "#{release_path}/#{s3_object_path}"

    end
  end

end
