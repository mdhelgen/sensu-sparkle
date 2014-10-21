knife[:cloudformation][:options][:capabilities] = ['CAPABILITY_IAM']

ec2_credentials = {
  :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :region => 'us-west-2'
}

ec2_credentials.each do |key, value|
  knife[key] = value
  knife[:cloudformation][:credentials][key] = value
end

# load a ./knife.local.rb file for overrides
knife_local_rb = File.join(File.dirname(__FILE__), 'knife.local.rb')
Chef::Config.from_file(knife_local_rb) if File.exist?(knife_local_rb)
