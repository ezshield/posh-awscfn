<#
.SYNOPSIS
A template describes your AWS infrastructure.

.DESCRIPTION
Templates include several major sections. The Resources section is the only section that is required:
 * Parameters
 * Mappings
 * Conditions
 * Resources
 * Outputs

Some sections in a template can be in any order. However, as you build your template, it might be helpful to use the logical ordering of the previous example, as values in one section might refer to values from a previous section.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html
#>
function New-CfnTemplate {

    param(
        [Parameter(Mandatory,Position=0)]
        [scriptblock]$TemplateBlock,

        [string]$Version="2010-09-09",
        [string]$Description,
        [System.Collections.IDictionary]$Metadata,
        [switch]$JSON,
        [switch]$Compress
    )

    $tMetadata   = [ordered]@{}
    $tParameters = [ordered]@{}
    $tMappings   = [ordered]@{}
    $tConditions = [ordered]@{}
    $tResources  = [ordered]@{}
    $tOutputs    = [ordered]@{}

    ## General-purpose extension mechanism:
    ##   tExtData is just a place to stash stuff
    ##   tExtPost is a collection of scriptblocks that will be invoked
    ##      (in order) with the template and tExtData as params
    $tExtData = [ordered]@{}
    $tExtPost = [ordered]@{}

    ## Copy over any Metadata that's available as a Param
    if ($Metadata) {
        foreach ($k in $Metadata.Keys) {
            $tMetadata[$k] = $Metadata[$k]
        }
    }

    & $TemplateBlock

    $t = [ordered]@{
        '$type' = "CfnTemplate"
        TemplateBody = [ordered]@{}
    }

    if ($Version    ) { $t.TemplateBody.AWSTemplateFormatVersion = $Version }
    if ($Description) { $t.TemplateBody.Description = $Description }

    if ($tMetadata   -and $tMetadata.Count  ) { $t.TemplateBody.Metadata   = $tMetadata   }
    if ($tParameters -and $tParameters.Count) { $t.TemplateBody.Parameters = $tParameters }
    if ($tMappings   -and $tMappings.Count  ) { $t.TemplateBody.Mappings   = $tMappings   }
    if ($tConditions -and $tConditions.Count) { $t.TemplateBody.Conditions = $tConditions }
    if ($tResources  -and $tResources.Count ) { $t.TemplateBody.Resources  = $tResources  }
    if ($tOutputs    -and $tOutputs.Count   ) { $t.TemplateBody.Outputs    = $tOutputs    }

    if ($tExtPost -and $tExtPost.Count) {
        foreach ($fKey in $tExtPost.Keys) {
            $fVal = $tExtPost[$fKey]
            $fVal.Invoke($t, $tExtData)
        } 
    }

    if ($JSON) {
        $convertParams = @{ Compress = $Compress }
        $t.TemplateBody | ConvertTo-Json -Depth 100 @convertParams
    }
    else {
        $t
    }
}
Set-Alias -Name Template -Value New-CfnTemplate

function Get-CfnTemplateExt {
<#
.SYNOPSIS
Provides access to the Extension support within a CloudFormation Template definition.
#>
    [OutputType(ParameterSetName="ExtData", [System.Collections.IDictionary])]
    [OutputType(ParameterSetName="ExtPost", [System.Collections.IDictionary])]
    param(
        [Parameter(ParameterSetName="ExtData")]
        [switch]$ExtData,
        [Parameter(ParameterSetName="ExtPost")]
        [switch]$ExtPost
    )

    $tExt = $null

    if ($ExtData) {
        $tExt = [System.Collections.IDictionary](Get-Variable -Name "tExtData" -ValueOnly)
    }
    if ($ExtPost) {
        $tExt = [System.Collections.IDictionary](Get-Variable -Name "tExtPost" -ValueOnly)
    }

    if (-not $tExt) {
        throw "Template Extensions are not in scope"
    }

    $tExt
}
