SparkleFormation.new(:sensu).load(:base).overrides do

  description 'Super cool Sensu deployment'

  %w[primary secondary].each do |tier|
    dynamic!(:launch_config, "rabbitmq_#{tier}",
             :security_groups => ref!(:sensu_internal_security_group),
             :public_ports => 5671,
             :run_list => _array(
               'role[rabbitmq]',
               'role[monitor]'))
  end

  dynamic!(:launch_config, 'redis',
           :security_groups => ref!(:sensu_internal_security_group),
           :instance_type => 'm3.medium',
           :run_list => _array(
             'role[redis]',
             'role[monitor]'))

  dynamic!(:launch_config, 'sensu',
           :security_groups => ref!(:sensu_internal_security_group),
           :run_list => _array(
             'role[sensu]',
             'role[monitor]'))

  dynamic!(:launch_config, 'sensu_enterprise',
           :security_groups => ref!(:sensu_internal_security_group),
           :run_list => _array(
             'role[sensu_enterprise]',
             'role[monitor]'))

  dynamic!(:launch_config, 'uchiwa',
           :security_groups => ref!(:sensu_internal_security_group),
           :public_ports => 3000,
           :instance_type => 'm1.small',
           :run_list => _array(
             'role[uchiwa]',
             'role[monitor]'))

  dynamic!(:auto_scaling_group, 'rabbitmq_secondary')
  dynamic!(:auto_scaling_group, 'rabbitmq_primary',
           :depends_on => :rabbitmq_secondary_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'redis',
           :depends_on => :rabbitmq_primary_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'sensu',
           :depends_on => :redis_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'sensu_enterprise',
           :depends_on => :redis_launch_wait_condition)

  dynamic!(:auto_scaling_group, 'uchiwa',
           :depends_on => _array(
             :sensu_launch_wait_condition,
             :sensu_enterprise_launch_wait_condition))
end
