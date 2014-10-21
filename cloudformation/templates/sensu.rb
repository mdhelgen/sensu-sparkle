SparkleFormation.new(:sensu).load(:base).overrides do

  description 'Super cool Sensu deployment'

  # Security groups
  resources(:sensu_internal_security_group) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'Sensu internal communication'
    end
  end

  resources(:rabbitmq_public_security_group) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'RabbitMQ public ports'
      security_group_ingress _array(
        -> {
          ip_protocol "tcp"
          from_port 5671
          to_port 5671
          cidr_ip "0.0.0.0/0"
        }
      )
    end
  end

  resources(:uchiwa_public_security_group) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'Uchiwa public ports'
      security_group_ingress _array(
        -> {
          ip_protocol "tcp"
          from_port 3000
          to_port 3000
          cidr_ip "0.0.0.0/0"
        }
      )
    end
  end

  # Launch configs
  dynamic!(:launch_config, 'rabbitmq',
           :security_groups => _array(
             ref!(:sensu_internal_security_group),
             ref!(:rabbitmq_public_security_group)))

  dynamic!(:launch_config, 'redis',
           :security_groups => ref!(:sensu_internal_security_group),
           :instance_type => 'm3.medium')

  dynamic!(:launch_config, 'sensu',
           :security_groups => ref!(:sensu_internal_security_group))

  dynamic!(:launch_config, 'uchiwa',
           :security_groups => _array(
             ref!(:sensu_internal_security_group),
             ref!(:uchiwa_public_security_group)),
           :instance_type => 't2.medium')

  # Auto-scaling groups
  dynamic!(:auto_scaling_group, 'rabbitmq')

  dynamic!(:auto_scaling_group, 'redis',
           :depends_on => :rabbitmq_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'sensu',
           :depends_on => :redis_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'uchiwa',
           :depends_on => :sensu_launch_wait_condition)
end
