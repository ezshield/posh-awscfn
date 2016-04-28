<#
WARNING:  THIS FILE IS AUTO-GENERATED! MANUAL CHANGES TO THIS
          FILE *WILL BE LOST* AFTER THE NEXT AUTO-GENERATION!

Generated By:  [ebekker]
Generated At:  [20160322_171703]
Generated On:  [EZS-001322]
Generated W/:  [Generate-CfnPseudoParameters.ps1]
#>

function Use-CfnPseudoParameter {
<#
.SYNOPSIS
Pseudo Parameters are parameters that are predefined by AWS CloudFormation. You do not declare them in your template.
.DESCRIPTION
You use them the same way as you would a Template Parameter, except that this cmdlet already returns the Pseudo Parameter in a "Ref function form" by default.

The following Pseudo Parameters are defined:
  * AccountId: Returns the AWS account ID of the account in which the stack is being created.
    o Type:  String 
    o Full:  AWS::AccountId
  * NotificationARNs: Returns the list of notification Amazon Resource Names (ARNs) for the current stack.
    o Type:  Array  (String)
    o Full:  AWS::NotificationARNs
  * NoValue: Used to unset a property for conditional properties.
    o Type:  String 
    o Full:  AWS::NoValue
  * Region: Returns a string representing the AWS Region in which the encompassing resource is being created.
    o Type:  String 
    o Full:  AWS::Region
  * StackId: Returns the ID of the stack.
    o Type:  String 
    o Full:  AWS::StackId
  * StackName: Returns the name of the stack.
    o Type:  String 
    o Full:  AWS::StackName
.LINK
docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html
#>
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateSet(
            'AccountId',
            'NotificationARNs',
            'NoValue',
            'Region',
            'StackId',
            'StackName'
            )]
        [string]$Parameter,
        [switch]$NameOnly
    )

    $FullName = "AWS::$($Parameter)"
    if ($NameOnly) {
        return $FullName
    }
    else {
        return @{ "Ref" = $FullName }
    }
}
Set-Alias -Name Pseudo -Value Use-CfnPseudoParameter
