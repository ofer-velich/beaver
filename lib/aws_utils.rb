require 'aws-sdk-core'

# return the ec2 host name
def ec2_public_hostname
    name = capture("curl http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null")
    return name.strip! || name
end

# return the ec2 region
def ec2_region
    availabilityzone = capture("ec2metadata | grep availability-zone |  awk '{print $2}'")
    aws_regions.each do |reg|
        if availabilityzone.include? reg
           return reg
        end
    end

    return nil
end


# return the sandbox RDS name for the 'api' site
def sandbox_rds_db_name
    name = capture("echo #{ec2_public_hostname} | md5sum")
    name = "#{name[0..32]}"
    return name.strip! || name
end

# return the sandbox RDS name for the 'cms' site
def sandbox_cms_rds_db_name
    name = capture("echo #{ec2_public_hostname} | md5sum")
    name = "cms#{name[0..32]}"
    return name.strip! || name
end

# return the sandbox s3 bucket name
def sandbox_s3_storage_bucket
    return "#{ec2_public_hostname}.mysite.com"
end

# return the sandbox cloud front distribution name 
def sandbox_cf_dist
    dist = describe_distribution(sandbox_s3_storage_bucket).domain_name
    
    return dist
end

def api_queue_name
    postfix = "#{ec2_public_hostname}".split('.')[0]
    return "https://sqs.us-east-1.amazonaws.com/410353812752/api-#{postfix}"
end

def create_ec2_client
    creds = Aws::Credentials.new( fetch(:aws_access_key),  fetch(:aws_secret_access_key))

    return Aws::EC2::Client.new(region: fetch(:region), credentials: creds)
end

def create_autoscale_client
    creds = Aws::Credentials.new( fetch(:aws_access_key),  fetch(:aws_secret_access_key))

    return Aws::AutoScaling::Client.new(region: fetch(:region), credentials: creds)
end

def create_cloudfront_client
    creds = Aws::Credentials.new( fetch(:aws_access_key),  fetch(:aws_secret_access_key))

    return Aws::CloudFront::Client.new(region: fetch(:region), credentials: creds)
end

def describe_distribution(origin_name)
    # create new client
    client = create_cloudfront_client()

    pages = client.list_distributions()

    pages.each do |page|
        page.distribution_list.items.each do |distribution|
            distribution.origins.items.each do |origin|
                if origin.domain_name.start_with?(origin_name)
                    return distribution
                end
            end
        end
    end

    return nil

end

# return an description of a given autoscale group 
def describe_auto_scaling_group(group_name)
    # create new client
    client = create_autoscale_client()

    pages = client.describe_auto_scaling_groups(auto_scaling_group_names: [group_name])
    
    return pages.first.auto_scaling_groups.first
end


# return an array of running instances description of a given autoscale group 
def describe_auto_scaling_group_running_instances(group_name)
    # create new client
    client = create_autoscale_client()

    pages = client.describe_auto_scaling_groups(auto_scaling_group_names: [group_name])
    
    group_description = pages.first.auto_scaling_groups.first
    
    filtered = []

    # list all currently existing servers in the auto scale group
    instances = group_description.instances

    instances.each do |instance|
        if is_working_instance?(instance.instance_id)
            filtered << instance
        end 
    end

    return filtered
end

def is_working_instance?(instance_id)
    # create new client
    client = create_ec2_client()

    instance_status = client.describe_instance_status(instance_ids: [instance_id]).instance_statuses.first

    return ! instance_status.nil? && instance_status.system_status.status == 'ok' && instance_status.instance_status.status == 'ok'
end



############
## Consts ##
############

# return the sandbox RDS host name 
def sandbox_rds_host_name
    return "mydb.cddmngem0xi6.us-east-1.rds.amazonaws.com"
end

def sandbox_rds_user
    return "root"
end

# return the sandbox RDS password 
def sandbox_rds_pwd
    return "lalalaGAGAGA"
end

def aws_regions
    return ["us-east-1", "us-west-2", "us-west-1", "eu-west-1", "eu-central-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "sa-east-1"]
end