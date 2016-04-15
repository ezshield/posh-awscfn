# **Output** *(Add-CfnOutput)*

## SYNOPSIS
The optional Outputs section declares output values that you want to view from the AWS CloudFormation console or that you want to return in response to describe stack calls.

## SYNTAX
```powershell
Add-CfnOutput [-OutputName] <String> [-Value] <Object> [[-Description] <String>] [<CommonParameters>]
```

## DESCRIPTION
For example, you can output the Amazon S3 bucket name for a stack so that you can easily find it.

Important
During a stack update, you cannot update outputs by themselves. You can update outputs only when you include changes that add, modify, or delete resources.

You can declare a maximum of 60 outputs in an AWS CloudFormation template.

Note that you can conditionally create an output by associating a condition with it. You must define the condition in the Conditions section of the template.

## PARAMETERS
### -OutputName &lt;String&gt;
An identifier for this output. The logical ID must be alphanumeric (A-Za-z0-9) and unique within the template.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Value &lt;Object&gt;
The value of the property that is returned by the aws cloudformation describe-stacks command. The value of an output can be literals, parameter references, pseudo parameters, a mapping value, and intrinsic functions.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Description &lt;String&gt;
A String type up to 4K in length describing the output value.
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
