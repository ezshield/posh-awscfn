#requires -Version 2.0 -Modules awscfn, AWS-HelperModule, AWSPowerShell
Get-AWSSAMLAssertion -rolescope Single
Set-AWSCredentials -AccessKey $global:stsroles.credentials.AccessKeyId -SecretKey $global:stsroles.credentials.SecretAccessKey -SessionToken $global:stsroles.credentials.SessionToken
Get-AWSDefaultRegion
Set-DefaultAWSRegion -Region $global:regionselection
$url = 'https://s3-ap-southeast-2.amazonaws.com/cf-templates-307300bd-b563-427f-9177-172f7402a0fc/'

$vpctemplate = New-CfnTemplate -JSON -Description 'Creates the VPC' -TemplateBlock {
  Add-CfnEC2_VPCResource -ResourceName ProdVPC -CidrBlock 10.10.0.0/16 -PropertiesBlock {
    Set-CfnResourceProperty -Name InstanceTenancy -Value default
    Set-CfnResourceProperty -Name EnableDnsSupport -Value $true
    Set-CfnResourceTag -TagKey Name -Value 'Production'
  }

  Add-CfnEC2_VPCResource -ResourceName DevVPC -CidrBlock 10.20.0.0/16 -PropertiesBlock {
    Set-CfnResourceProperty -Name InstanceTenancy -Value default
    Set-CfnResourceProperty -Name EnableDnsSupport -Value $true
    Set-CfnResourceTag -TagKey Name -Value 'Development'
  }

  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet1a -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2a
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.1.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Public (PROD) 2a'
  }
  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet1b -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2b
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.2.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Public (PROD) 2b'
  }
  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet1c -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2c
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.3.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Public (PROD) 2c'
  }

  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet1a -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.1.0/24
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true    
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2a
    Set-CfnResourceTag -TagKey Name -Value 'Public (DEV) 2a'
  }
  
  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet1b -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.2.0/24
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true    
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2b
    Set-CfnResourceTag -TagKey Name -Value 'Public (DEV) 2b'
  }
  
  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet1c -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.3.0/24
    Set-CfnResourceProperty -Name MapPublicIpOnLaunch -Value $true    
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2c
    Set-CfnResourceTag -TagKey Name -Value 'Public (DEV) 2c'
  }

  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet2a -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2a
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.4.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Private (PROD) 2a'
  }
    
  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet2b -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2b
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.5.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Private (PROD) 2b'
  }

  Add-CfnEC2_SubnetResource -ResourceName VPC1Subnet2c -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC) 
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2c
    Set-CfnResourceProperty -Name CidrBlock -Value 10.10.6.0/24
    Set-CfnResourceTag -TagKey Name -Value 'Private (PROD) 2c'
  }
  
  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet2a -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.4.0/24
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2a
    Set-CfnResourceTag -TagKey Name -Value 'Private (DEV) 2a'
  }

  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet2b -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.5.0/24
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2b
    Set-CfnResourceTag -TagKey Name -Value 'Private (DEV) 2b'
  }
  
  Add-CfnEC2_SubnetResource -ResourceName VPC2Subnet2c -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceProperty -Name CidrBlock -Value 10.20.6.0/24
    Set-CfnResourceProperty -Name AvailabilityZone -Value ap-southeast-2c
    Set-CfnResourceTag -TagKey Name -Value 'Private (DEV) 2c'
  }

  Add-CfnEC2_RouteTableResource -ResourceName ProdVPCPublicRouteTable -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC)
    Set-CfnResourceTag -TagKey Name -Value 'Public (PROD)'
  }

  Add-CfnEC2_RouteTableResource -ResourceName DevVPCPublicRouteTable -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceTag -TagKey Name -Value 'Public (DEV)'
  }  

  Add-CfnEC2_RouteTableResource -ResourceName ProdVPCPrivateRouteTable -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC)
    Set-CfnResourceTag -TagKey Name -Value 'Private (PROD)'
  }

  Add-CfnEC2_RouteTableResource -ResourceName DevVPCPrivateRouteTable -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
    Set-CfnResourceTag -TagKey Name -Value 'Private (DEV)'
  } 
   
  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPublicRouteTableAssoc2a `
  -DependsOn VPC1Subnet1a -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1a)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPublicRouteTableAssoc2b `
  -DependsOn VPC1Subnet1b -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1b)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPublicRouteTableAssoc2c `
  -DependsOn VPC1Subnet1c -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1c)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPublicRouteTableAssoc2a `
  -DependsOn VPC2Subnet1a -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1a)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPublicRouteTableAssoc2b `
  -DependsOn VPC2Subnet1b -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1b)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPublicRouteTableAssoc2c `
  -DependsOn VPC2Subnet1c -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPublicRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1c)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPrivateRouteTableAssoc2a `
  -DependsOn VPC1Subnet2a -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2a)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPrivateRouteTableAssoc2b `
  -DependsOn VPC1Subnet2b -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2b)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName ProdVPCPrivateRouteTableAssoc2c `
  -DependsOn VPC1Subnet2c -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2c)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPrivateRouteTableAssoc2a `
  -DependsOn VPC2Subnet2a -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2a)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPrivateRouteTableAssoc2b `
  -DependsOn VPC2Subnet2b -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2b)      
  }

  Add-CfnEC2_SubnetRouteTableAssociationResource -ResourceName DevVPCPrivateRouteTableAssoc2c `
  -DependsOn VPC2Subnet2c -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2c)      
  }

  Add-CfnEC2_InternetGatewayResource -ResourceName ProdVPCIGW -DependsOn ProdVPC -PropertiesBlock {
    Set-CfnResourceTag -TagKey Name -Value 'Production'
  }

  Add-CfnEC2_InternetGatewayResource -ResourceName DevVPCIGW -DependsOn DevVPC -PropertiesBlock {
    Set-CfnResourceTag -TagKey Name -Value 'Development'
  }

  Add-CfnEC2_VPCGatewayAttachmentResource -ResourceName ProdVPCIGWAttach -DependsOn ProdVPCIGW -PropertiesBlock {
    Set-CfnResourceProperty -Name InternetGatewayId -Value (Use-CfnRefFunction -LogicalName ProdVPCIGW)
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName ProdVPC)
  }

  Add-CfnEC2_VPCGatewayAttachmentResource -ResourceName DevVPCIGWAttach -DependsOn DevVPCIGW -PropertiesBlock {
    Set-CfnResourceProperty -Name InternetGatewayId -Value (Use-CfnRefFunction -LogicalName DevVPCIGW)
    Set-CfnResourceProperty -Name VpcId -Value (Use-CfnRefFunction -LogicalName DevVPC)
  }

  Add-CfnEC2_EIPResource -ResourceName ProdVPCNGWEIP -Domain vpc
  Add-CfnEC2_EIPResource -ResourceName DevVPCNGWEIP -Domain vpc
  
  Add-CfnEC2_NatGatewayResource -ResourceName ProdVPCNGW -DependsOn ProdVPCNGWEIP -PropertiesBlock {
    Set-CfnResourceProperty -Name AllocationId -Value (Use-CfnGetAttFunction -ResourceName ProdVPCNGWEIP `
    -AttributeName AllocationId)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1a)            
  }

  Add-CfnEC2_NatGatewayResource -ResourceName DevVPCNGW -DependsOn DevVPCNGWEIP -PropertiesBlock {
    Set-CfnResourceProperty -Name AllocationId -Value (Use-CfnGetAttFunction -ResourceName DevVPCNGWEIP `
    -AttributeName AllocationId)
    Set-CfnResourceProperty -Name SubnetId -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1a)            
  }

  Add-CfnEC2_RouteResource -ResourceName ProdVPCPublicRoute -DependsOn ProdVPCIGWAttach -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPublicRouteTable)
    Set-CfnResourceProperty -Name DestinationCidrBlock -Value '0.0.0.0/0'
    Set-CfnResourceProperty -Name GatewayId -Value (Use-CfnRefFunction -LogicalName ProdVPCIGW)      
  }

  Add-CfnEC2_RouteResource -ResourceName DevVPCPublicRoute -DependsOn ProdVPCIGWAttach -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPublicRouteTable)
    Set-CfnResourceProperty -Name DestinationCidrBlock -Value '0.0.0.0/0'
    Set-CfnResourceProperty -Name GatewayId -Value (Use-CfnRefFunction -LogicalName DevVPCIGW)      
  }

  Add-CfnEC2_RouteResource -ResourceName ProdVPCPrivateRoute -DependsOn ProdVPCNGW -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName ProdVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name DestinationCidrBlock -Value '0.0.0.0/0'
    Set-CfnResourceProperty -Name NatGatewayId -Value (Use-CfnRefFunction -LogicalName ProdVPCNGW)      
  }

  Add-CfnEC2_RouteResource -ResourceName DevVPCPrivateRoute -DependsOn DevVPCNGW -PropertiesBlock {
    Set-CfnResourceProperty -Name RouteTableId -Value (Use-CfnRefFunction -LogicalName DevVPCPrivateRouteTable)
    Set-CfnResourceProperty -Name DestinationCidrBlock -Value '0.0.0.0/0'
    Set-CfnResourceProperty -Name NatGatewayId -Value (Use-CfnRefFunction -LogicalName DevVPCNGW)   
  }
   
  Add-CfnOutput -Description 'Exports the ID of the Prod VPC' -OutputName ProdVPCExport -Value (Use-CfnRefFunction -LogicalName ProdVPC) -Export @{
    Name = (Use-CfnSubFunction -Value 'VPC1-ProdVPC')
  }
  Add-CfnOutput -Description 'Exports the ID of the Dev VPC' -OutputName DevVPCExport -Value (Use-CfnRefFunction -LogicalName DevVPC) -Export @{
    Name = (Use-CfnSubFunction -Value 'VPC1-DevVPC')
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod public subnet in 2a' -OutputName ProdPublicSubnetExport2a -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1a) -Export @{
    Name = 'VPC1-ProdPublic2a'
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod public subnet in 2b' -OutputName ProdPublicSubnetExport2b -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1b) -Export @{
    Name = 'VPC1-ProdPublic2b'
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod public subnet in 2c' -OutputName ProdPublicSubnetExport2c -Value (Use-CfnRefFunction -LogicalName VPC1Subnet1c) -Export @{
    Name = 'VPC1-ProdPublic2c'
  }
  Add-CfnOutput -Description 'Exports the ID of the Dev public subnet in 2a' -OutputName DevPublicSubnetExport2a -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1a) -Export @{
    Name = 'VPC1-DevPublic2a'
  }
  Add-CfnOutput -Description 'Exports the ID of the Dev public subnet in 2b' -OutputName DevPublicSubnetExport2b -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1b) -Export @{
    Name = 'VPC1-DevPublic2b'
  }
  Add-CfnOutput -Description 'Exports the ID of the Dev public subnet in 2c' -OutputName DevPublicSubnetExport2c -Value (Use-CfnRefFunction -LogicalName VPC2Subnet1c) -Export @{
    Name = 'VPC1-DevPublic2c'
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod private subnet in 2a' -OutputName ProdPrivateSubnetExport2a -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2a) -Export @{
    Name = 'VPC1-ProdPrivate2a'
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod private subnet in 2b' -OutputName ProdPrivateSubnetExport2b -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2b) -Export @{
    Name = 'VPC1-ProdPrivate2b'
  }
  Add-CfnOutput -Description 'Exports the ID of the Prod private subnet in 2c' -OutputName ProdPrivateSubnetExport2c -Value (Use-CfnRefFunction -LogicalName VPC1Subnet2c) -Export @{
    Name = 'VPC1-ProdPrivate2c'
  }
  Add-CfnOutput -Description 'Exports the ID of the Dev private subnet in 2a' -OutputName DevPrivateSubnetExport2a -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2a) -Export @{
    Name = 'VPC1-DevPrivate2a'
  }          
  Add-CfnOutput -Description 'Exports the ID of the Dev private subnet in 2b' -OutputName DevPrivateSubnetExport2b -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2b) -Export @{
    Name = 'VPC1-DevPrivate2b'
  } 
  Add-CfnOutput -Description 'Exports the ID of the Dev private subnet in 2c' -OutputName DevPrivateSubnetExport2c -Value (Use-CfnRefFunction -LogicalName VPC2Subnet2c) -Export @{
    Name = 'VPC1-DevPrivate2c'
  } 
} 

Write-S3Object -BucketName 'cf-templates-307300bd-b563-427f-9177-172f7402a0fc' -Key 'vpc.template' -Content $vpctemplate
Remove-Variable -Name vpctemplate