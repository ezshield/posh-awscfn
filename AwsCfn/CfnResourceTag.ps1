<#
.SYNOPSIS
You can use the AWS CloudFormation Resource Tags property to apply tags to resources, which can help you identify and categorize those resources.

.DESCRIPTION
You can tag only resources for which AWS CloudFormation supports tagging. For information about which resources you can tag with AWS CloudFormation, see the individual resources in AWS Resource Types Reference.

.PARAMETER TagKey
The key name of the tag. You can specify a value that is 1 to 128 Unicode characters in length and cannot be prefixed with aws:. You can use any of the following characters: the set of Unicode letters, digits, whitespace, _, ., /, =, +, and -.

.PARAMETER Value
The value for the tag. You can specify a value that is 1 to 128 Unicode characters in length and cannot be prefixed with aws:. You can use any of the following characters: the set of Unicode letters, digits, whitespace, _, ., /, =, +, and -.

.PARAMETER PropertyName
Use this to override the default Tags property upon which the Tag is defined.

Tags are normally attached to a Resource definition as a collection on the Property 'Tags', however a few Resource types also allow you to define Tag-like structures on either alternative or additional Properties.

For example, the "AWS::DataPipeline::Pipeline" Resource type allows you to define Tags on its 'PipelineTags' Property, whereas the "AWS::CodeDeploy::DeploymentGroup" Resource type allows you to define Tag-like values on its 'Ec2TagFilters' Property.

.PARAMETER TagProperties
Use this to add additional properties or attributes to a Tag definition.

Normally, a Tag is composed of a Key (a unique identifier) and a Value.  But some Resources support Properties whose value models a Tag-like structure that may also support additional properties or attributes for each Tag entry.

For example, the "AWS::CodeDeploy::DeploymentGroup" Resource type allows you to define a Property 'Ec2TagFilters' with Tag-like entries that also contain a 'Type' property.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-resource-tags.html
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html
#>
function Set-CfnResourceTag {
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateLength(1, 128)]
        [string]$TagKey,
        [Parameter(Mandatory,Position=1)]
        [ValidateLength(1, 128)]
        [string]$Value,
        [string]$PropertyName='Tags',
        [System.Collections.IDictionary]$TagProperties
    )

    $rProperties = [System.Collections.IDictionary](Get-Variable -Name "rProperties" -ValueOnly)
    if (-not $tResources) {
        throw "Resource Properties collection is not in scope"
    }

    if ($rProperties.Contains($PropertyName)) {
        $tags = $rProperties[$PropertyName]
        if (-not ($tags -is [System.Collections.IList])) {
            throw "Resource Property existing value is not compatible with a Tag collection"
        }
    }
    else {
        $tags = New-Object System.Collections.ArrayList
    }

    foreach ($t in $tags) {
        $tHash = $t -as [System.Collections.IDictionary]
        if ($tHash -and $tHash.Contains('Key') -and $tHash['Key'] -eq $TagKey) {
            throw "Duplicate Tag key [$TagName]"
        }
    }

    $newTag = [ordered]@{
        Key = $TagKey
        Value = $Value
    }
    if ($TagProperties) {
        foreach ($tpk in $TagProperties.Keys) {
            $newTag[$tpk] = $TagProperties[$tpk]
        }
    }

    ## Add the newly constructed Tag to the resource property collection
    $tags += $newTag

    ## Update the resource property value to the updated collection
    $rProperties[$PropertyName] = $tags
}
Set-Alias -Name Tag -Value Set-CfnResourceTag
