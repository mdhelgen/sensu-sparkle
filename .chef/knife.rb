knife[:cloudformation][:options][:capabilities] = ['CAPABILITY_IAM']

knife[:cloudformation][:credentials] = {
  :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :region => 'us-west-2'
}
