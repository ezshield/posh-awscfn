
function Use-CfnAndCondition {
<#
.SYNOPSIS
Returns true if all the specified conditions evaluate to true, or returns false if any one of the conditions evaluates to false. Fn::And acts as an AND operator. The minimum number of conditions that you can include is 2, and the maximum is 10.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e103666
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateCount(2, 10)]
        [array]$Conditions=@()
    )

    return @{ "Fn::And" = $Conditions }
}
Set-Alias -Name Fn-And -Value Use-CfnAndCondition


function Use-CfnEqualsCondition {
<#
.SYNOPSIS
Compares if two values are equal. Returns true if the two values are equal or false if they aren't.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e103748
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$LValue,
        [Parameter(Mandatory,Position=1)]
        [object]$RValue
    )

    return @{ "Fn::Equals" = @( $LValue, $RValue ) }
}
Set-Alias -Name Fn-Equals -Value Use-CfnEqualsCondition


function Use-CfnIfCondition {
<#
.SYNOPSIS
Returns one value if the specified condition evaluates to true and another value if the specified condition evaluates to false.
.DESCRIPTION
Currently, AWS CloudFormation supports the Fn::If intrinsic function in the metadata attribute, update policy attribute, and property values in the Resources section and Outputs sections of a template. You can use the AWS::NoValue pseudo parameter as a return value to remove the corresponding property.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e103823
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$ConditionName,
        [Parameter(Mandatory,Position=1)]
        [object]$IfTrue,
        [Parameter(Mandatory,Position=2)]
        [object]$IfFalse
    )

    return @{ "Fn::If" = @( $ConditionName, $IfTrue, $IfFalse ) }
}
Set-Alias -Name Fn-If -Value Use-CfnIfCondition


function Use-CfnNotCondition {
<#
.SYNOPSIS
Returns true for a condition that evaluates to false or returns false for a condition that evaluates to true. Fn::Not acts as a NOT operator.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e104002
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [object]$Condition
    )

    return @{ "Fn::Not" = @( $Condition ) }
}
Set-Alias -Name Fn-Not -Value Use-CfnNotCondition


function Use-CfnOrCondition {
<#
.SYNOPSIS
Returns true if any one of the specified conditions evaluate to true, or returns false if all of the conditions evaluates to false. Fn::Or acts as an OR operator. The minimum number of conditions that you can include is 2, and the maximum is 10.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e104090
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateCount(2, 10)]
        [array]$Conditions=@()
    )

    return @{ "Fn::Or" = $Conditions }
}
Set-Alias -Name Fn-Or -Value Use-CfnOrCondition

function Use-CfnCondition {
<#
.SYNOPSIS
Returns a reference to another named Condition.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ConditionName
    )

    return @{ "Condition" = $ConditionName }
}
Set-Alias -Name Fn-Condition -Value Use-CfnCondition

