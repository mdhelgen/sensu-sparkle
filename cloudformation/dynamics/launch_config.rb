SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|

  resources("#{_name}_security_group".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description "#{_name} public TCP ports"
    end
  end

  public_ports = [_config[:public_ports]].flatten.compact + [22]

  public_ports.each do |port|
    resources("#{_name}_security_group_#{port}".to_sym) do
      type 'AWS::EC2::SecurityGroupIngress'
      properties do
        group_name ref!("#{_name}_security_group".to_sym)
        ip_protocol 'tcp'
        from_port port
        to_port port
        cidr_ip '0.0.0.0/0'
      end
    end
  end

  resources("#{_name}_launch_wait_handle".to_sym) do
    type 'AWS::CloudFormation::WaitConditionHandle'
  end

  additional_security_groups = [_config[:security_groups]].flatten.compact

  resources("#{_name}_launch_config".to_sym) do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id (_config[:image_id] || 'ami-a94e0c99')
      instance_type (_config[:instance_type] || 'c3.large')
      key_name 'sensu-sparkle'
      security_groups [_cf_ref("#{_name}_security_group".to_sym)] + additional_security_groups
      user_data(
        _cf_base64(
          _cf_join(
            "#!/bin/bash\n",
            "apt-get -y install python-setuptools\n",
            "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
            'cfn-init -v --region ',
            _cf_ref('AWS::Region'),
            ' -s ',
            _cf_ref('AWS::StackName'),
            " -r #{_process_key("#{_name}_launch_config")} --access-key ",
            _cf_ref(:cfn_keys),
            ' --secret-key ',
            _cf_attr(:cfn_keys, :secret_access_key),
            "\n",
            "cfn-signal -e $? -r 'Chef Server Configuration' '",
            _cf_ref("#{_name}_launch_wait_handle".to_sym),
            "'\n"
          )
        )
      )
    end
    metadata('AWS::CloudFormation::Authentication') do
      s3_access_creds do
        _camel_keys_set(:auto_disable)
        type 'S3'
        accessKeyId _cf_ref(:cfn_keys)
        secretKey _cf_attr(:cfn_keys, :secret_access_key)
        buckets _array('sensu-sparkle')
      end
    end
    metadata('AWS::CloudFormation::Init') do
      _camel_keys_set(:auto_disable)
      config do
        files('/etc/chef/ohai/hints/ec2.json') do
          content do
            hint 'ec2'
          end
        end
        files('/etc/aws/cfn-user.json') do
          content do
            user _cf_ref(:cfn_user)
            access_key _cf_ref(:cfn_keys)
            secret_key _cf_attr(:cfn_keys, :secret_access_key)
          end
        end
        files('/etc/chef/chef-validator.pem') do
          source 'https://sensu-sparkle.s3-us-west-2.amazonaws.com/chef-validator.pem'
          mode '000400'
          owner 'root'
          group 'root'
          authentication 'S3AccessCreds'
        end
        files('/etc/chef/encrypted_data_bag_secret') do
          source 'https://sensu-sparkle.s3-us-west-2.amazonaws.com/encrypted_data_bag_secret'
          mode '000400'
          owner 'root'
          group 'root'
          authentication 'S3AccessCreds'
        end
        files('/etc/chef/first_run.json') do
          content do
            run_list (_config[:run_list] || [])
            aws do
              stack_name _cf_ref('AWS::StackName')
              stack_id _cf_ref('AWS::StackId')
              security_group _cf_ref("#{_name}_security_group".to_sym)
            end
          end
          mode '000644'
          owner 'root'
          group 'root'
          authentication 'S3AccessCreds'
        end
        files('/etc/chef/client.rb') do
          content _cf_join(
            "log_level :info\n",
            "log_location '/var/log/chef/client.log'\n",
            "chef_server_url 'https://api.opscode.com/organizations/sensu-sparkle'\n",
            "validation_key '/etc/chef/chef-validator.pem'\n",
            "validation_client_name 'sensu-sparkle-validator'\n",
            "encrypted_data_bag_secret '/etc/chef/encrypted_data_bag_secret'\n"
          )
          mode '000644'
          owner 'root'
          client 'root'
        end
        commands('01_omnibus_installer') do
          command 'curl -L https://www.opscode.com/chef/install.sh | bash -s --'
          test 'test ! -e /opt/chef'
        end
        commands('02_log_dir') do
          command 'mkdir -p /var/log/chef'
          test 'test ! -e /var/log/chef'
        end
        commands('03_chef_node_name') do
          command 'echo "node_name \'`curl -s http://169.254.169.254/latest/meta-data/instance-id`\'" >> /etc/chef/client.rb'
          test '! grep node_name /etc/chef/client.rb'
        end
        commands('04_chef_first_run') do
          command '/usr/bin/chef-client -j /etc/chef/first_run.json'
          test 'test -e /etc/chef/chef-validator.pem'
        end
      end
    end
  end
end
