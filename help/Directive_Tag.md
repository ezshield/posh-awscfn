# **Tag** *(Set-CfnResourceTag)*

## SYNOPSIS
You can use the AWS CloudFormation Resource Tags property to apply tags to resources, which can help you identify and categorize those resources.

## SYNTAX
```powershell
Set-CfnResourceTag [-TagKey] <String> [-Value] <Object> [-PropertyName <String>] [-TagProperties <IDictionary>] [<CommonParameters>]
```

## DESCRIPTION
You can tag only resources for which AWS CloudFormation supports tagging. For information about which resources you can tag with AWS CloudFormation, see the individual resources in AWS Resource Types Reference.

## PARAMETERS
### -TagKey &lt;String&gt;
The key name of the tag. You can specify a value that is 1 to 128 Unicode characters in length and cannot be prefixed with aws:. You can use any of the following characters: the set of Unicode letters, digits, whitespace, _, ., /, =, +, and -.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Value &lt;Object&gt;
The value for the tag. You can specify a value that is 1 to 128 Unicode characters in length and cannot be prefixed with aws:. You can use any of the following characters: the set of Unicode letters, digits, whitespace, _, ., /, =, +, and -.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PropertyName &lt;String&gt;
Use this to override the default Tags property upon which the Tag is defined.

Tags are normally attached to a Resource definition as a collection on the Property 'Tags', however a few Resource types also allow you to define Tag-like structures on either alternative or additional Properties.

For example, the "AWS::DataPipeline::Pipeline" Resource type allows you to define Tags on its 'PipelineTags' Property, whereas the "AWS::CodeDeploy::DeploymentGroup" Resource type allows you to define Tag-like values on its 'Ec2TagFilters' Property.
```
Required?                    false
Position?                    named
Default value                Tags
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -TagProperties &lt;IDictionary&gt;
Use this to add additional properties or attributes to a Tag definition.

Normally, a Tag is composed of a Key (a unique identifier) and a Value.  But some Resources support Properties whose value models a Tag-like structure that may also support additional properties or attributes for each Tag entry.

For example, the "AWS::CodeDeploy::DeploymentGroup" Resource type allows you to define a Property 'Ec2TagFilters' with Tag-like entries that also contain a 'Type' property.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
