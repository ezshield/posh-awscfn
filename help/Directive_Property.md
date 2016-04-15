# **Property** *(Set-CfnResourceProperty)*

## SYNOPSIS
Resource properties are additional options that you can specify for a resource.

## SYNTAX
```powershell
Set-CfnResourceProperty [-Name] <String> [-Value] <Object> [<CommonParameters>]
```

## DESCRIPTION
For example, for each Amazon EC2 instance, you must specify an AMI ID for that instance. You declare the AMI ID as a property of the instance.

You can add a Resource using either the generic Resource declaration or a strongly-typed Resource-specific declaration.  For the latter, you can specify any of the defined Properties as cmdlet parameters, however you are restricted to only specifying literal values of the appropriate type and conforming to the associated parameter validation rules.

However, each strongly-typed Resource, and the generic Resource declartion support an optional Properties scriptblock which allows you to specify one or more Property declarations which can resolve to a CloudFormation runtime-evaluated Function call.

## PARAMETERS
### -Name &lt;String&gt;
The name of a Property to assign a value to for the parent Resource.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Value &lt;Object&gt;
The value to assign to the named Property for the parent Resource.

Property values can be literal strings, lists of strings, booleans, Parameter references, Pseudo references, or the value returned by a Function. When a Property value is a literal string, the value is enclosed in double quotes.

Note that you can conditionally create a Resource by associating a condition with it. You must define the Condition in the Conditions section of the Template.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
