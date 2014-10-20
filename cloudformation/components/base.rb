SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  resources.cfn_user do
    type 'AWS::IAM::User'
    properties.path '/'
    properties.policies _array(
      -> {
        policy_name 'cfn_access'
        policy_document.statement _array(
          -> {
            effect 'Allow'
            action 'cloudformation:DescribeStackResource'
            resource '*'
          }
        )
      },
      -> {
        policy_name 's3_access'
        policy_document.statement _array(
          -> {
            effect 'Allow'
            action _array('s3:Get*', 's3:List*')
            resource 'arn:aws:s3:::sensu-sparkle/*'
          }
        )
      }
    )
  end

  resources.cfn_keys do
    type 'AWS::IAM::AccessKey'
    properties.user_name ref!(:cfn_user)
  end
end
