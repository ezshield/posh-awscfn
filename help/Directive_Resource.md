# **Resource** *(Add-CfnResource)*

## SYNOPSIS
The required Resources section declare the AWS resources that you want as part of your stack, such as an Amazon EC2 instance or an Amazon S3 bucket.

## SYNTAX
```powershell
Add-CfnResource [-ResourceName] <String> [-Type] <String> [-Properties <IDictionary>] [-Condition <Object>] [[-PropertiesBlock] <ScriptBlock>] [<CommonParameters>]

Add-CfnResource [-ResourceName] <String> [-RawType] <String> [-Properties <IDictionary>] [-Condition <Object>] [[-PropertiesBlock] <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
You must declare each resource separately; however, you can specify multiple resources of the same type.

Resources can be added to a template using one of two forms, either a generic Resource declaration or a strongly-typed Resource-specific declaration.  This cmdlet provides the generic Resource declaration support.

## PARAMETERS
### -ResourceName &lt;String&gt;
The logical ID which must be alphanumeric (A-Za-z0-9) and unique within the template.

You use the logical name to reference the resource in other parts of the template. For example, if you want to map an Amazon Elastic Block Store to an Amazon EC2 instance, you reference the logical IDs to associate the block stores with the instance.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Type &lt;String&gt;
The resource type identifies the type of resource that you are declaring.

For example, the AWS::EC2::Instance declares an Amazon EC2 instance. For a list of all the resource types, see AWS Resource Types Reference.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -RawType &lt;String&gt;
An alternative to the Type parameter, this allows you to specify an unrestricted and unvalidated type name.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Properties &lt;IDictionary&gt;
Resource properties are additional options that you can specify for a resource.

For example, for each Amazon EC2 instance, you must specify an AMI ID for that instance. You declare the AMI ID as a property of the instance.

If a resource does not require any properties to be declared, omit the properties.

Property values can be literal strings, lists of strings, Booleans, parameter references, pseudo references, or the value returned by a function. These rules apply when you combine literals, lists, references, and functions to obtain a value.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Condition &lt;Object&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PropertiesBlock &lt;ScriptBlock&gt;
Allows you to declare a block of one or more Property statements.
```
Required?                    false
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
