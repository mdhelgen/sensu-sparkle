SparkleFormation.new(:sensu).load(:base).overrides do

  description 'Super cool Sensu deployment'

  resources(:sensu_internal_security_group) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'Sensu internal communication'
    end
  end

  dynamic!(:launch_config, 'rabbitmq', :stack_security_group => ref!(:sensu_internal_security_group))

  parameters.rabbitmq_nodes do
    type 'Number'
    description 'Number of RabbitMQ nodes for ASG.'
    default '3'
  end

  resources.rabbitmq_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:rabbitmq_launch_config)
      min_size ref!(:rabbitmq_nodes)
      max_size ref!(:rabbitmq_nodes)
    end
  end

  dynamic!(:launch_config, 'redis', :stack_security_group => ref!(:sensu_internal_security_group))

  parameters.redis_nodes do
    type 'Number'
    description 'Number of Redis nodes for ASG.'
    default '1'
  end

  resources.redis_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:redis_launch_config)
      min_size ref!(:redis_nodes)
      max_size ref!(:redis_nodes)
    end
  end

  dynamic!(:launch_config, 'sensu',
    :stack_security_group => ref!(:sensu_internal_security_group),
    :depends_on => _array('RabbitmqAutoscale')
  )

  parameters.sensu_nodes do
    type 'Number'
    description 'Number of Sensu nodes for ASG.'
    default '2'
  end

  resources.sensu_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:sensu_launch_config)
      min_size ref!(:sensu_nodes)
      max_size ref!(:sensu_nodes)
    end
  end
end
