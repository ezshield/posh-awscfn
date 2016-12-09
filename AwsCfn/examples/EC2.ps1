#requires -Version 2.0 -Modules awscfn, AWS-HelperModule, AWSPowerShell
Get-AWSSAMLAssertion -rolescope Single
Set-AWSCredentials -AccessKey $global:stsroles.credentials.AccessKeyId -SecretKey $global:stsroles.credentials.SecretAccessKey -SessionToken $global:stsroles.credentials.SessionToken
Get-AWSDefaultRegion
Set-DefaultAWSRegion -Region $global:regionselection
$url = 'https://s3-ap-southeast-2.amazonaws.com/cf-templates-307300bd-b563-427f-9177-172f7402a0fc/'

$ec2template = New-CfnTemplate -JSON -Description 'Creates the EC2 instances' -TemplateBlock {  
  Add-CfnIAM_RoleResource -ResourceName AutomationRole -AssumeRolePolicyDocument @{
    Version   = '2012-10-17'
    Statement = @(
      @{
        Effect    = 'Allow'
        Principal = @{
          Service = @('ec2.amazonaws.com')
        }
        Action    = @('sts:AssumeRole')
      }
    )
  } -Path '/' -Policies @(
    [ordered]@{
      PolicyName     = 'AutomationPolicy'
      PolicyDocument = @{
        Version   = '2012-10-17'
        Statement = @(
          [ordered]@{
            Effect   = 'Allow'
            Action   = @(
              's3:Get*', 
              's3:List*', 
              'ec2:Describe*'
            )
            Resource = '*'
          }
        )
      }
    }
  )

  Add-CfnIAM_InstanceProfileResource -ResourceName AutomationRoleProfile -Path '/' -PropertiesBlock {
    Set-CfnResourceProperty -Name Roles -Value @(
      (Use-CfnRefFunction -LogicalName AutomationRole)
    )
  }
  
  Add-CfnEC2_SecurityGroupResource -ResourceName BastSG01 -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnImportFunction -Value 'VPC1-DevVPC')
    Set-CfnResourceProperty -Name GroupDescription -Value 'Allows remote access to the bastion'          
    Set-CfnResourceTag -TagKey Name -Value 'BastionSG01'      
  } -SecurityGroupIngress @(
    [ordered]@{
      IpProtocol = 'tcp'
      FromPort   = '3389'
      ToPort     = '3389'
      CidrIp     = '0.0.0.0/0'
    }
  )

  Add-CfnEC2_SecurityGroupResource -ResourceName PSGallerySG01 -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnImportFunction -Value 'VPC1-DevVPC')
    Set-CfnResourceProperty -Name GroupDescription -Value 'Allows remote access to the private PSGallery'          
    Set-CfnResourceTag -TagKey Name -Value 'PSGallerySG01'      
  } -SecurityGroupIngress @(
    [ordered]@{
      IpProtocol            = 'tcp'
      FromPort              = '3389'
      ToPort                = '3389'
      SourceSecurityGroupId = (Use-CfnRefFunction -LogicalName BastSG01)
    }
  )
  
  Add-CfnEC2_InstanceResource -ResourceName DevBastion01 -PropertiesBlock {
    Set-CfnResourceProperty -Name ImageId -Value 'ami-d97e40ba'
    Set-CfnResourceProperty -Name KeyName -Value 'AW-KP-02'    
    Set-CfnResourceProperty -Name IamInstanceProfile -Value (Use-CfnRefFunction -LogicalName AutomationRoleProfile) 
    Set-CfnResourceProperty -Name SecurityGroupIds -Value @((Use-CfnRefFunction -LogicalName BastSG01))  
    Set-CfnResourceProperty -Name InstanceType -Value 't2.micro'
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnImportFunction -Value 'VPC1-DevPublic2a')
    Set-CfnResourceTag -TagKey Name -Value 'DevBastion01'
    Set-CfnResourceProperty -Name BlockDeviceMappings -Value @(
      @{
        DeviceName = '/dev/sda1'
        Ebs        = @{ 
          VolumeSize = '30' 
        }
      }
    )                             
  }
  
  Add-CfnEC2_SecurityGroupResource -ResourceName PSGalleryELBSG01 -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnImportFunction -Value 'VPC1-DevVPC')
    Set-CfnResourceProperty -Name GroupDescription -Value 'Allows HTTP through the ELB'          
    Set-CfnResourceTag -TagKey Name -Value 'PSGalleryELBSG01'      
  } -SecurityGroupIngress @(
    [ordered]@{
      IpProtocol = 'tcp'
      FromPort   = '80'
      ToPort     = '80'
      CidrIp     = '0.0.0.0/0'
    }
  )
  
  Add-CfnElasticLoadBalancing_LoadBalancerResource -ResourceName PSGalleryELB01 -DependsOn PSGalleryELBSG01 -PropertiesBlock {
    Set-CfnResourceProperty -Name LoadBalancerName -Value PSGalleryELB01    
    Set-CfnResourceProperty -Name Subnets -Value (Use-CfnImportFunction -Value VPC1-DevPublic2a), (Use-CfnImportFunction -Value VPC1-DevPublic2b), (Use-CfnImportFunction -Value VPC1-DevPublic2c)    
    Set-CfnResourceProperty -Name Scheme -Value internet-facing
    Set-CfnResourceProperty -Name SecurityGroups -Value @((Use-CfnRefFunction -LogicalName PSGalleryELBSG01))
    Set-CfnResourceProperty -Name Listeners -Value @(@{
        LoadBalancerPort = '80'
        InstancePort     = '80'
        Protocol         = 'HTTP'
      }
    )     
  }
  
  Add-CfnAutoScaling_LaunchConfigurationResource -ResourceName PSGalleryLaunchConfig -AssociatePublicIpAddress $false -PropertiesBlock {
    Set-CfnResourceProperty -Name ImageId -Value 'ami-d97e40ba'
    Set-CfnResourceProperty -Name KeyName -Value 'AW-KP-02'   
    Set-CfnResourceProperty -Name SecurityGroups -Value @((Use-CfnRefFunction -LogicalName PSGallerySG01))
    Set-CfnResourceProperty -Name InstanceType -Value 't2.micro'
    Set-CfnResourceProperty -Name IamInstanceProfile -Value (Use-CfnRefFunction -LogicalName AutomationRoleProfile)          
  }

  Add-CfnAutoScaling_AutoScalingGroupResource -ResourceName PSGalleryASG01 -MinSize 1 -MaxSize 1 -PropertiesBlock {
    Set-CfnResourceProperty -Name LaunchConfigurationName -Value (Use-CfnRefFunction -LogicalName PSGalleryLaunchConfig)  
    Set-CfnResourceProperty -Name VPCZoneIdentifier -Value (Use-CfnImportFunction -Value VPC1-DevPrivate2a), (Use-CfnImportFunction -Value VPC1-DevPrivate2b), (Use-CfnImportFunction -Value VPC1-DevPrivate2c)
    Set-CfnResourceProperty -Name LoadBalancerNames -Value @((Use-CfnRefFunction -LogicalName PSGalleryELB01))                 
  } -HealthCheckGracePeriod 300 -HealthCheckType EC2 -TerminationPolicies NewestInstance
  
  Add-CfnEC2_SecurityGroupIngressResource -ResourceName PSGalleryELBIngress01 -PropertiesBlock {
    Set-CfnResourceProperty -Name GroupId -Value (Use-CfnRefFunction -LogicalName PSGallerySG01)  
    Set-CfnResourceProperty -Name IpProtocol -Value 'tcp' 
    Set-CfnResourceProperty -Name FromPort -Value '80' 
    Set-CfnResourceProperty -Name ToPort -Value '80'  
    Set-CfnResourceProperty -Name SourceSecurityGroupId -Value (Use-CfnRefFunction -LogicalName PSGalleryELBSG01)  
  }
}

Write-S3Object -BucketName 'cf-templates-307300bd-b563-427f-9177-172f7402a0fc' -Key 'ec2.template' -Content $ec2template
Remove-Variable -Name ec2template