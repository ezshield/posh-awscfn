#requires -Version 2.0 -Modules AwsCfn, AWS-HelperModule, AWSPowerShell, Microsoft.PowerShell.Utility
Import-Module -Name C:\Users\anthony\Documents\GitHub\posh-awscfn\AwsCfn\AwsCfn.psd1
Get-AWSSAMLAssertion -rolescope Single
Set-AWSCredentials -AccessKey $global:stsroles.credentials.AccessKeyId -SecretKey $global:stsroles.credentials.SecretAccessKey -SessionToken $global:stsroles.credentials.SessionToken
Get-AWSDefaultRegion
Set-DefaultAWSRegion -Region $global:regionselection

New-S3Bucket -BucketName ('cf-templates-'+(New-Guid))
#New-Item -Path C:\Temp\Cloudformation -ItemType directory
$url = 'https://s3-ap-southeast-2.amazonaws.com/cf-templates-307300bd-b563-427f-9177-172f7402a0fc/'

$parenttemplate = New-CfnTemplate -JSON -Description 'Parent template to deploy the other resources' -TemplateBlock {
  Add-CfnCloudFormation_StackResource -ResourceName VPCStack1 -TemplateURL ($url + 'vpc.template')
  Add-CfnCloudFormation_StackResource -ResourceName EC2Stack1 -TemplateURL ($url + 'ec2.template') -DependsOn VPCStack1
}

Write-S3Object -BucketName 'cf-templates-307300bd-b563-427f-9177-172f7402a0fc' -Key 'parent.template' -Content $parenttemplate


Remove-CFNStack -StackName Parent1 -Force
New-CFNStack -StackName Parent1 -TemplateURL ($url + 'parent.template') -Capability CAPABILITY_IAM, CAPABILITY_NAMED_IAM
Update-CFNStack -StackName Parent1 -TemplateURL ($url + 'parent.template') -Capability CAPABILITY_IAM, CAPABILITY_NAMED_IAM