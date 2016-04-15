Set-Alias -Name StackPolicy -Value Set-CfnStackPolicy
function Set-CfnStackPolicy {
<#
.SYNOPSIS
You can prevent stack resources from being unintentionally updated or deleted during a stack update by using stack policies.

.DESCRIPTION
Stack policies apply only during stack updates and should be used only as a fail-safe mechanism to prevent accidental updates to certain stack resources. Do not use stack policies to control access to AWS resources or actions; instead, use AWS Identity and Access Management (IAM).

By default, all resources in a stack can be updated by anyone with update permissions. However, during an update, some resources might require an interruption or might be completely replaced, which could result in new physical IDs or completely new storage. To ensure that no one inadvertently updates these resources, you can set a stack policy. The stack policy prevents anyone from accidentally updating resources that are protected. If you want to update protected resources, you must explicitly specify those resources during a stack update.

Important
After you set a stack policy, all resources in the stack are protected by default, even if you didn't explicitly set a policy on those resources. For any resources that you still want to allow updates on, you must specify an explicit Allow statement for those resources.

.PARAMETER Deny
Indicates the actions that you specify are denied on the resource that you specify. You can specify only Deny or Allow per statement.

Important
If a stack policy includes any overlapping statements (a resource that is allowed and denied), a Deny statement always overrides an Allow statement. If you want ensure that a resource is protected, use a Deny statement for that resource.

.PARAMETER Allow
Indicates the actions that you specify are allowed on the resource that you specify. You can specify only Deny or Allow per statement.

Important
If a stack policy includes any overlapping statements (a resource that is allowed and denied), a Deny statement always overrides an Allow statement. If you want ensure that a resource is protected, use a Deny statement for that resource.

.PARAMETER Actions
Specifies the update actions that are denied or allowed.  You can only specify one of Actions or NotActions parameters.

.PARAMETER NotActions
Specifies the update actions that are not denied or allowed.  You can only specify one of Actions or NotActions parameters.

.PARAMETER Resources
Specifies the logical IDs of the resources that the policy applies to. If you want to specify types of resources, use the ResourceTypes parameter.

.PARAMETER NotResources
Specifies the logical IDs of the resources that the policy does not apply to. If you want to specify types of resources, use the ResourceTypes parameter.

.PARAMETER ResourceTypes
Specifies the resource type that the policy applies to.  You can also use a wild card with resource types with the ResourceTypesLike parameter.

.PARAMETER ResourceTypesLike
You can use a wild card with resource types. For example, you can deny update permissions to all Amazon EC2 resources, such as instances, security groups, and subnets by using a wild card such as "AWS::EC2::*".

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html#stack-policy-reference
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ParameterSetName="Deny")]
        [switch]$Deny,
        [Parameter(Mandatory,Position=0,ParameterSetName="Allow")]
        [switch]$Allow,

        [ValidateSet('Modify','Replace','Delete','*')]
        [string[]]$Actions,
        [ValidateSet('Modify','Replace','Delete','*')]
        [string[]]$NotActions,

        [string[]]$Resources,
        [string[]]$NotResources,
        [ValidateSet(
            ,'AWS::AutoScaling::AutoScalingGroup'
            ,'AWS::AutoScaling::LaunchConfiguration'
            ,'AWS::AutoScaling::LifecycleHook'
            ,'AWS::AutoScaling::ScalingPolicy'
            ,'AWS::AutoScaling::ScheduledAction'
            ,'AWS::AutoScaling::Trigger'
            ,'AWS::CloudFormation::Stack'
            ,'AWS::CloudFormation::WaitCondition'
            ,'AWS::CloudFormation::WaitConditionHandle'
            ,'AWS::CloudFront::Distribution'
            ,'AWS::CloudTrail::Trail'
            ,'AWS::CloudWatch::Alarm'
            ,'AWS::CodeDeploy::Application'
            ,'AWS::CodeDeploy::DeploymentConfig'
            ,'AWS::CodeDeploy::DeploymentGroup'
            ,'AWS::CodePipeline::CustomActionType'
            ,'AWS::CodePipeline::Pipeline'
            ,'AWS::Config::ConfigRule'
            ,'AWS::Config::ConfigurationRecorder'
            ,'AWS::Config::DeliveryChannel'
            ,'AWS::DataPipeline::Pipeline'
            ,'AWS::DirectoryService::MicrosoftAD'
            ,'AWS::DirectoryService::SimpleAD'
            ,'AWS::DynamoDB::Table'
            ,'AWS::EC2::CustomerGateway'
            ,'AWS::EC2::DHCPOptions'
            ,'AWS::EC2::EIP'
            ,'AWS::EC2::EIPAssociation'
            ,'AWS::EC2::Instance'
            ,'AWS::EC2::InternetGateway'
            ,'AWS::EC2::NatGateway'
            ,'AWS::EC2::NetworkAcl'
            ,'AWS::EC2::NetworkAclEntry'
            ,'AWS::EC2::NetworkInterface'
            ,'AWS::EC2::NetworkInterfaceAttachment'
            ,'AWS::EC2::PlacementGroup'
            ,'AWS::EC2::Route'
            ,'AWS::EC2::RouteTable'
            ,'AWS::EC2::SecurityGroup'
            ,'AWS::EC2::SecurityGroupEgress'
            ,'AWS::EC2::SecurityGroupIngress'
            ,'AWS::EC2::SpotFleet'
            ,'AWS::EC2::Subnet'
            ,'AWS::EC2::SubnetNetworkAclAssociation'
            ,'AWS::EC2::SubnetRouteTableAssociation'
            ,'AWS::EC2::Volume'
            ,'AWS::EC2::VolumeAttachment'
            ,'AWS::EC2::VPC'
            ,'AWS::EC2::VPCDHCPOptionsAssociation'
            ,'AWS::EC2::VPCEndpoint'
            ,'AWS::EC2::VPCGatewayAttachment'
            ,'AWS::EC2::VPCPeeringConnection'
            ,'AWS::EC2::VPNConnection'
            ,'AWS::EC2::VPNConnectionRoute'
            ,'AWS::EC2::VPNGateway'
            ,'AWS::EC2::VPNGatewayRoutePropagation'
            ,'AWS::ECR::Repository'
            ,'AWS::ECS::Cluster'
            ,'AWS::ECS::Service'
            ,'AWS::ECS::TaskDefinition'
            ,'AWS::EFS::FileSystem'
            ,'AWS::EFS::MountTarget'
            ,'AWS::ElastiCache::CacheCluster'
            ,'AWS::ElastiCache::ParameterGroup'
            ,'AWS::ElastiCache::ReplicationGroup'
            ,'AWS::ElastiCache::SecurityGroup'
            ,'AWS::ElastiCache::SecurityGroupIngress'
            ,'AWS::ElastiCache::SubnetGroup'
            ,'AWS::ElasticBeanstalk::Application'
            ,'AWS::ElasticBeanstalk::ApplicationVersion'
            ,'AWS::ElasticBeanstalk::ConfigurationTemplate'
            ,'AWS::ElasticBeanstalk::Environment'
            ,'AWS::ElasticLoadBalancing::LoadBalancer'
            ,'AWS::Elasticsearch::Domain'
            ,'AWS::EMR::Cluster'
            ,'AWS::EMR::InstanceGroupConfig'
            ,'AWS::EMR::Step'
            ,'AWS::IAM::AccessKey'
            ,'AWS::IAM::Group'
            ,'AWS::IAM::InstanceProfile'
            ,'AWS::IAM::ManagedPolicy'
            ,'AWS::IAM::Policy'
            ,'AWS::IAM::Role'
            ,'AWS::IAM::User'
            ,'AWS::IAM::UserToGroupAddition'
            ,'AWS::Kinesis::Stream'
            ,'AWS::KMS::Key'
            ,'AWS::Lambda::EventSourceMapping'
            ,'AWS::Lambda::Function'
            ,'AWS::Lambda::Permission'
            ,'AWS::Logs::Destination'
            ,'AWS::Logs::LogGroup'
            ,'AWS::Logs::LogStream'
            ,'AWS::Logs::MetricFilter'
            ,'AWS::Logs::SubscriptionFilter'
            ,'AWS::OpsWorks::App'
            ,'AWS::OpsWorks::ElasticLoadBalancerAttachment'
            ,'AWS::OpsWorks::Instance'
            ,'AWS::OpsWorks::Layer'
            ,'AWS::OpsWorks::Stack'
            ,'AWS::RDS::DBCluster'
            ,'AWS::RDS::DBClusterParameterGroup'
            ,'AWS::RDS::DBInstance'
            ,'AWS::RDS::DBParameterGroup'
            ,'AWS::RDS::DBSecurityGroup'
            ,'AWS::RDS::DBSecurityGroupIngress'
            ,'AWS::RDS::DBSubnetGroup'
            ,'AWS::RDS::EventSubscription'
            ,'AWS::RDS::OptionGroup'
            ,'AWS::Redshift::Cluster'
            ,'AWS::Redshift::ClusterParameterGroup'
            ,'AWS::Redshift::ClusterSecurityGroup'
            ,'AWS::Redshift::ClusterSecurityGroupIngress'
            ,'AWS::Redshift::ClusterSubnetGroup'
            ,'AWS::Route53::HealthCheck'
            ,'AWS::Route53::HostedZone'
            ,'AWS::Route53::RecordSet'
            ,'AWS::Route53::RecordSetGroup'
            ,'AWS::S3::Bucket'
            ,'AWS::S3::BucketPolicy'
            ,'AWS::SDB::Domain'
            ,'AWS::SNS::Topic'
            ,'AWS::SNS::TopicPolicy'
            ,'AWS::SQS::Queue'
            ,'AWS::SQS::QueuePolicy'
            ,'AWS::SSM::Document'
            ,'AWS::WAF::ByteMatchSet'
            ,'AWS::WAF::IPSet'
            ,'AWS::WAF::Rule'
            ,'AWS::WAF::SqlInjectionMatchSet'
            ,'AWS::WAF::WebACL'
            ,'AWS::WorkSpaces::Workspace'
        )]
        [string[]]$ResourceTypes,
        [string[]]$ResourceTypesLike
    )

    if ($Actions -and $NotActions) {
        throw "You cannot combine Actions and NotActions parameters"
    }

    if ($Resources -and $NotResources) {
        throw "You cannot combine Resources and NotResources parameters"
    }

    if ($ResourceTypes -and $ResourceTypesLike) {
        throw "You cannot combine ResourceTypes and ResourceTypesLike parameters"
    }

    if (($ResourceTypes -or $ResourceTypesLike) -and (-not $Resources) -and (-not $NotResources)) {
        $Resources = "*"
    }

    ## This directive uses the "Template Extensions" feature to
    ## collect policy statements and then process them and attach
    ## them as as a Stack Policy definition to the Template root

    $tExtData = Get-CfnTemplateExt -ExtData
    $tExtPost = Get-CfnTemplateExt -ExtPost
    if (-not $tExtData -or -not $tExtPost) {
        throw "Template Extensions cannot be accessed"
    }
    if ($tExtData.StackPolicyStatements -eq $null) {
        $tExtData.StackPolicyStatements = new-object System.Collections.ArrayList
        $tExtPost.StackPolicyStatements = {
                ## This is the scriptblock that will post-process
                ## the statements after the template has been defined
                param($t, $tExtData)
                $polStatements = [System.Collections.ArrayList]($tExtData.StackPolicyStatements)
                if ($polStatements -and $polStatements.Count) {
                    $t.StackPolicy = [ordered]@{
                        Statement = $polStatements
                    }
                }
            }
    }
    $tStackPolicyStatements = $tExtData.StackPolicyStatements

    $stmt = @{
        Effect    = $(if ($Allow) { "Allow" } elseif ($Deny) { "Deny" })
        Principal = "*"
    }

    if ($Actions) {
        $stmt.Action = $Actions
    }
    elseif ($NotActions) {
        $stmt.NotAction = $NotActions
    }

    if ($Resources) {
        $stmt.Resource = ($Resources |
                % { if ($_ -like 'LogicalResourceId/*') { $_ } else { "LogicalResourceId/$_" } })
    }
    elseif ($NotResources) {
        $stmt.NotResource = ($NotResources |
                % { if ($_ -like 'LogicalResourceId/*') { $_ } else { "LogicalResourceId/$_" } })
    }

    if ($ResourceTypes) {
        $stmt.Condition = @{
            StringEquals = @{
                ResourceType = $ResourceTypes
            }
        }
    }
    elseif ($ResourceTypesLike) {
        $stmt.Condition = @{
            StringLike = @{
                ResourceType = $ResourceTypesLike
            }
        }
    }

    $tStackPolicyStatements.Add($stmt) | Out-Null
}
