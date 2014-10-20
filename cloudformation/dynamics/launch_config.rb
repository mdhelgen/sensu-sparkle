SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|

  resources("#{_name}_security_group".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'Enable SSH'
      security_group_ingress _array(
        -> {
          ip_protocol 'tcp'
          from_port 22
          to_port 22
          cidr_ip '0.0.0.0/0'
        }
      )
    end
  end

  resources("#{_name}_launch_wait_handle".to_sym) do
    type 'AWS::CloudFormation::WaitConditionHandle'
    if _config[:depends_on]
      depends_on _config[:depends_on]
    end
  end

  resources("#{_name}_launch_config".to_sym) do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id 'ami-a94e0c99'
      instance_type 'c3.large'
      key_name 'sensu-sparkle'
      security_groups [_cf_ref("#{_name}_security_group".to_sym), _config[:stack_security_group]]
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
            "validation_client_name 'sensu-sparkle-validator'\n"
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
        commands('03_chef_first_run') do
          command '/usr/bin/chef-client -j /etc/chef/first_run.json'
          test 'test -e /etc/chef/chef-validator.pem'
        end
      end
    end
  end
end
