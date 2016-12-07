<#
.SYNOPSIS
The optional Outputs section declares output values that you want to view from the AWS CloudFormation console or that you want to return in response to describe stack calls.

.DESCRIPTION
For example, you can output the Amazon S3 bucket name for a stack so that you can easily find it.

Important
During a stack update, you cannot update outputs by themselves. You can update outputs only when you include changes that add, modify, or delete resources.

You can declare a maximum of 60 outputs in an AWS CloudFormation template.

Note that you can conditionally create an output by associating a condition with it. You must define the condition in the Conditions section of the template.

.PARAMETER OutputName
An identifier for this output. The logical ID must be alphanumeric (A-Za-z0-9) and unique within the template.

.PARAMETER Value
The value of the property that is returned by the aws cloudformation describe-stacks command. The value of an output can be literals, parameter references, pseudo parameters, a mapping value, and intrinsic functions.

.PARAMETER Description
A String type up to 4K in length describing the output value.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html
#>
function Add-CfnOutput {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$OutputName,

        ## Needs to be an object to support
        ## rich types like objects and arrays
        [Parameter(Mandatory,Position=1)]
        [object]$Value,

        ## Needs to be an object to support
        ## rich types like objects and arrays
        [Parameter(Position=2)]
        [object]$Export,
		
        [Parameter(Position=3)]
        [ValidateLength(1,4000)]
        [string]$Description
    )

    $tOutputs = [System.Collections.IDictionary](Get-Variable -Name "tOutputs" -ValueOnly)
    if (-not $tOutputs) {
        throw "Template Outputs collection is not in scope"
    }

    if ($tOutputs.Contains($OutputName)) {
        throw "Duplicate Output name [$OutputName]"
    }

    $o = [ordered]@{ Value = $Value }
    if ($Description) { $o.Description = $Description }
    if ($Export) { $o.Export = $Export }	
    $tOutputs.Add($OutputName, $o)
}
Set-Alias -Name Output -Value Add-CfnOutput