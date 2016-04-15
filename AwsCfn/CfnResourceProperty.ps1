<#
.SYNOPSIS
Resource properties are additional options that you can specify for a resource.

.DESCRIPTION
For example, for each Amazon EC2 instance, you must specify an AMI ID for that instance. You declare the AMI ID as a property of the instance.

You can add a Resource using either the generic Resource declaration or a strongly-typed Resource-specific declaration.  For the latter, you can specify any of the defined Properties as cmdlet parameters, however you are restricted to only specifying literal values of the appropriate type and conforming to the associated parameter validation rules.

However, each strongly-typed Resource, and the generic Resource declartion support an optional Properties scriptblock which allows you to specify one or more Property declarations which can resolve to a CloudFormation runtime-evaluated Function call.

.PARAMETER Name
The name of a Property to assign a value to for the parent Resource.

.PARAMETER Value
The value to assign to the named Property for the parent Resource.

Property values can be literal strings, lists of strings, booleans, Parameter references, Pseudo references, or the value returned by a Function. When a Property value is a literal string, the value is enclosed in double quotes.

Note that you can conditionally create a Resource by associating a condition with it. You must define the Condition in the Conditions section of the Template.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html
#>
function Set-CfnResourceProperty {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Name,
        [Parameter(Mandatory,Position=1)]
        [object]$Value
    )

    $rProperties = [System.Collections.IDictionary](Get-Variable -Name "rProperties" -ValueOnly)
    if (-not $tResources) {
        throw "Resource Properties collection is not in scope"
    }
        
    if ($rProperties.Contains($Name)) {
        throw "Duplicate Property name [$Name]"
    }

    $rProperties.Add($Name, $Value)
}
Set-Alias -Name Property -Value Set-CfnResourceProperty
