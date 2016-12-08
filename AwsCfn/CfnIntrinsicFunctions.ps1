
function Use-CfnBase64Function {
<#
.SYNOPSIS
The intrinsic function Fn::Base64 returns the Base64 representation of the input string. This function is typically used to pass encoded data to Amazon EC2 instances by way of the UserData property.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-base64.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$ValueToEncode
    )

    return @{ "Fn::Base64" = $ValueToEncode }
}
Set-Alias -Name Fn-Base64 -Value Use-CfnBase64Function


function Use-CfnFindInMapFunction {
<#
.SYNOPSIS
The intrinsic function Fn::FindInMap returns the value corresponding to keys in a two-level map that is declared in the Template Mappings section.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$MapName,
        [Parameter(Mandatory,Position=1)]
        [object]$TopLevelKey,
        [Parameter(Mandatory,Position=2)]
        [object]$SecondLevelKey
    )

    return @{ "Fn::FindInMap" = @( $MapName, $TopLevelKey, $SecondLevelKey ) }
}
Set-Alias -Name Fn-FindInMap -Value Use-CfnFindInMapFunction


function Use-CfnGetAttFunction {
<#
.SYNOPSIS
The intrinsic function Fn::GetAtt returns the value of an attribute from a resource in the template.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$ResourceName,
        [Parameter(Mandatory,Position=1)]
        [object]$AttributeName
    )

    return @{ "Fn::GetAtt" = @( $ResourceName, $AttributeName ) }
}
Set-Alias -Name Fn-GetAtt -Value Use-CfnGetAttFunction


function Use-CfnGetAZsFunction {
<#
.SYNOPSIS
The intrinsic function Fn::GetAZs returns an array that lists Availability Zones for a specified region.

.DESCRIPTION
Because customers have access to different Availability Zones, the intrinsic function Fn::GetAZs enables template authors to write templates that adapt to the calling user's access. That way you don't have to hard-code a full list of Availability Zones for a specified region.

Note
For the EC2-Classic platform, the Fn::GetAZs function returns all Availability Zones for a region. For the EC2-VPC platform, the Fn::GetAZs function returns only Availability Zones that have a default subnet unless none of the Availability Zones has a default subnet; in that case, all Availability Zones are returned.

IAM permissions

The permissions that you need in order to use the Fn::GetAZs function depend on the platform in which you're launching Amazon EC2 instances. For both platforms, you need permissions to the Amazon EC2 DescribeAvailabilityZones and DescribeAccountAttributes actions. For EC2-VPC, you also need permissions to the Amazon EC2 DescribeSubnets action.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html
#>
    param(
        [Parameter(Position=0)]
        [object]$Region=""
    )

    return @{ "Fn::GetAZs" = $Region }
}
Set-Alias -Name Fn-GetAZs -Value Use-CfnGetAZsFunction


function Use-CfnJoinFunction {
<#
.SYNOPSIS
The intrinsic function Fn::Join appends a set of values into a single value, separated by the specified delimiter. If a delimiter is the empty string, the set of values are concatenated with no delimiter.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html
#>
    [CmdletBinding(DefaultParameterSetName="Values")]
    param(
        [Parameter(Position=0)]
        [object]$Delimiter='',
        [Parameter(Mandatory,Position=1,ParameterSetName="Values")]
        [array]$Values=@(),
        [Parameter(Mandatory,Position=1,ParameterSetName="ValuesRef")]
        [object]$ValuesRef
    )

    if ($ValuesRef) {
        if ($ValuesRef -is [string]) {
            return @{ "Fn::Join" = @( $Delimiter, @{ Ref = $ValuesRef } ) }
        }
        else {
            return @{ "Fn::Join" = @( $Delimiter, $ValuesRef ) }
        }
    }
    else {
        return @{ "Fn::Join" = @( $Delimiter, $Values ) }
    }
}
Set-Alias -Name Fn-Join -Value Use-CfnJoinFunction


function Use-CfnSelectFunction {
<#
.SYNOPSIS
The intrinsic function Fn::Select returns a single object from a list of objects by index.
.DESCRIPTION
Important
Fn::Select does not check for null values or if the index is out of bounds of the array. Both conditions will result in a stack error, so you should be certain that the index you choose is valid, and that the list contains non-null values.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-select.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$Index,
        [Parameter(Mandatory,Position=1)]
        [array]$List=@()
    )

    return @{ "Fn::Select" = @( $Index, $List ) }
}
Set-Alias -Name Fn-Select -Value Use-CfnSelectFunction


function Use-CfnRefFunction {
<#
.SYNOPSIS
The intrinsic function Ref returns the value of the specified parameter or resource.
.DESCRIPTION
  * When you specify a parameter's logical name, it returns the value of the parameter.
  * When you specify a resource's logical name, it returns a value that you can typically use to refer to that resource, such as a physical ID.
When you are declaring a resource in a template and you need to specify another template resource by name, you can use the Ref to refer to that other resource. In general, Ref returns the name of the resource. 

Tip
You can also use Ref to add values to Output messages.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$LogicalName
    )

    return @{ "Ref" = $LogicalName }
}
Set-Alias -Name Fn-Ref -Value Use-CfnRefFunction

function Use-CfnImportFunction {
<#
.SYNOPSIS
The intrinsic function Fn::ImportValue returns the value of an output exported by another stack.
.DESCRIPTION
  * When you specify a parameter's logical name, it returns the value of the parameter.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Value
    )

    return @{ "Fn::ImportValue" = $Value }
}
Set-Alias -Name Fn-Import -Value Use-CfnImportFunction

function Use-CfnSubFunction {
<#
.SYNOPSIS
The intrinsic function Fn::Sub substitutes variables in an input string with values that you specify.
.DESCRIPTION
  * When you specify a parameter's logical name, it returns the value of the parameter.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Value
    )

    return @{ "Fn::Sub" = $Value }
}
Set-Alias -Name Fn-Sub -Value Use-CfnSubFunction
