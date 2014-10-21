SparkleFormation.new(:sensu).load(:base).overrides do

  description 'Super cool Sensu deployment'

  # Security groups
  resources(:sensu_internal_security_group) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'Sensu internal communication group'
    end
  end

  %w[tcp udp].each do |protocol|
    resources("sensu_internal_security_#{protocol}".to_sym) do
      type 'AWS::EC2::SecurityGroupIngress'
      properties do
        group_name ref!(:sensu_internal_security_group)
        ip_protocol protocol
        from_port 0
        to_port 65535
        source_security_group_name ref!(:sensu_internal_security_group)
      end
    end
  end

  # Launch configs
  %w[primary secondary].each do |tier|
    dynamic!(:launch_config, "rabbitmq_#{tier}",
             :security_groups => ref!(:sensu_internal_security_group),
             :public_ports => 5671,
             :run_list => _array('role[rabbitmq]'))
  end

  dynamic!(:launch_config, 'redis',
           :security_groups => ref!(:sensu_internal_security_group),
           :instance_type => 'm3.medium',
           :run_list => _array('role[redis]'))

  dynamic!(:launch_config, 'sensu',
           :security_groups => ref!(:sensu_internal_security_group))

  dynamic!(:launch_config, 'uchiwa',
           :security_groups => ref!(:sensu_internal_security_group),
           :public_ports => 3000,
           :instance_type => 'm1.small')

  # Auto-scaling groups
  dynamic!(:auto_scaling_group, 'rabbitmq_secondary')
  dynamic!(:auto_scaling_group, 'rabbitmq_primary',
           :depends_on => :rabbitmq_secondary_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'redis',
           :depends_on => :rabbitmq_primary_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'sensu',
           :depends_on => :redis_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'uchiwa',
           :depends_on => :sensu_launch_wait_condition)
end
