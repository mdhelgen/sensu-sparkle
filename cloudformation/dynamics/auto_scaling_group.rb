SparkleFormation.dynamic(:auto_scaling_group) do |_name, _config = {}|
  parameters("#{_name}_nodes".to_sym) do
    type 'Number'
    description 'Number of nodes for ASG'
  end

  depends_on_resources = [_config[:depends_on]].flatten.compact.map {|d| _process_key(d)}

  resources("#{_name}_auto_scaling_group".to_sym) do
    type 'AWS::AutoScaling::AutoScalingGroup'
    depends_on depends_on_resources unless depends_on_resources.empty?
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!("#{_name}_launch_config".to_sym)
      min_size ref!("#{_name}_nodes".to_sym)
      max_size ref!("#{_name}_nodes".to_sym)
    end
  end

  resources("#{_name}_launch_wait_condition".to_sym) do
    type 'AWS::CloudFormation::WaitCondition'
    depends_on _process_key("#{_name}_auto_scaling_group".to_sym)
    properties do
      count _cf_ref("#{_name}_nodes".to_sym)
      handle _cf_ref("#{_name}_launch_wait_handle".to_sym)
      timeout '1800'
    end
  end
end
