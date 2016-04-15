<#
.SYNOPSIS
The optional Mappings section matches a key to a corresponding set of named values.

.DESCRIPTION
As an example, if you want to set values based on a region, you can create a mapping that uses the region name as a key and contains the values you want to specify for each specific region. You use the Fn::FindInMap intrinsic function to retrieve values in a map.

You cannot include parameters, pseudo parameters, or intrinsic functions in the Mappings section.

The keys and values in mappings must be literal strings. For each mapping, you must declare a logical name and the sets of values to map. The following example shows a Mappings section containing a single mapping named Mapping01.

.PARAMETER MappingName
For each Mapping, you must declare a logical name. The logical name must be alphanumeric and unique among all logical names within the tTemplate.

.PARAMETER Map
The keys and values in mappings must resolve to literal strings.

AWS-specific parameter types are AWS values such as Amazon EC2 key pair names and VPC IDs. AWS CloudFormation validates these parameter values against existing values in users' AWS accounts. AWS-specific parameter types are helpful in catching invalid values at the start of creating or updating a stack.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html
#>
function Add-CfnMapping {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$MappingName,
        [Parameter(Mandatory,Position=1)]
        [System.Collections.IDictionary]$Map
    )

    $tMappings = [System.Collections.IDictionary](Get-Variable -Name "tMappings" -ValueOnly)
    if (-not $tMappings) {
        throw "Template Mappings collection is not in scope"
    }

    if ($tMappings.Contains($MappingName)) {
        throw "Duplicate Mapping name [$MappingName]"
    }

    $tMappings[$MappingName] = $Map
}
Set-Alias -Name Mapping -Value Add-CfnMapping
