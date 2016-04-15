# **Parameter** *(Add-CfnParameter)*

## SYNOPSIS
You can use the optional Parameters section to pass values into your template when you create a stack.

## SYNTAX
```powershell
Add-CfnParameter [-ParameterName] <String> [-Type] <String> [[-Description] <String>] [[-ConstraintDescription] <String>] [-ConsoleGroup <String>] [-ConsoleLabel <String>] [-Default <Object>] [-NoEcho] [-AllowedValues <Array>] [-AllowedPattern <String>] [-MinLength <Int32>] [-MaxLength <Int32>] [-MinValue <Int32>] [-MaxValue <Int32>] [<CommonParameters>]
```

## DESCRIPTION
With parameters, you can create templates that are customized each time you create a stack. Each parameter must contain a value when you create a stack. You can specify a default value to make the parameter optional.

You have a maximum of 60 parameters in an AWS CloudFormation template.

## PARAMETERS
### -ParameterName &lt;String&gt;
For each Parameter, you must declare a logical name. The logical name must be alphanumeric and unique among all logical names within the Template. After you declare the parameter's logical name, you can specify the parameter's properties.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Type &lt;String&gt;
You must declare parameters as one of following types: String, Number, CommaDelimitedList, or an AWS-specific type. For String, Number, and AWS-specific parameter types, you can define constraints that AWS CloudFormation uses to validate the value of the parameter.

AWS-specific parameter types are AWS values such as Amazon EC2 key pair names and VPC IDs. AWS CloudFormation validates these parameter values against existing values in users' AWS accounts. AWS-specific parameter types are helpful in catching invalid values at the start of creating or updating a stack.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Description &lt;String&gt;

```
Required?                    false
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ConstraintDescription &lt;String&gt;

```
Required?                    false
Position?                    4
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ConsoleGroup &lt;String&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ConsoleLabel &lt;String&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Default &lt;Object&gt;
Needs to be an object to support
rich types like objects and arrays
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -NoEcho &lt;SwitchParameter&gt;

```
Required?                    false
Position?                    named
Default value                False
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -AllowedValues &lt;Array&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -AllowedPattern &lt;String&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -MinLength &lt;Int32&gt;

```
Required?                    false
Position?                    named
Default value                0
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -MaxLength &lt;Int32&gt;

```
Required?                    false
Position?                    named
Default value                0
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -MinValue &lt;Int32&gt;

```
Required?                    false
Position?                    named
Default value                0
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -MaxValue &lt;Int32&gt;

```
Required?                    false
Position?                    named
Default value                0
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
