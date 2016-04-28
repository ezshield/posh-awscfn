
function Add-CfnCustomResource {
<#
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ResourceName,
        [Parameter(Mandatory,Position=1)]
        [string]$ServiceToken,
        [ValidateLength(1,60)]
        [ValidatePattern('[A-Za-z0-9_\@\-]+')]
        [string]$CustomType,
        [string]$Version='1.0',

        [System.Collections.IDictionary]$Tags,
        [System.Collections.IDictionary]$Properties,

        ## Resource-common params
        [ValidateSet('Delete','Retain')]
        [string]$DeletionPolicy,
        [hashtable]$Metadata,
        [array]$DependsOn,
        [Parameter(Position=2)]
        [scriptblock]$PropertiesBlock,
        [object]$Condition
    )

    $tResources = [System.Collections.IDictionary](Get-Variable -Name "tResources" -ValueOnly)
    if (-not $tResources) {
        throw "Template Resrouces collection is not in scope"
    }
    if ($tResources.Contains($ResourceName)) {
        throw "Duplicate Resource name [$ResourceName]"
    }

    if ($CustomType) {
        $r = [ordered]@{ Type = "Custom::$CustomType" }
    }
    else {
        $r = [ordered]@{ Type = 'AWS::CloudFormation::CustomResource' }
    }
    if ($Version) {
        $r.Version = $Version
    }
    $rProperties = [ordered]@{
        ServiceToken = $ServiceToken
    }

    ## Resource Properties
    if ($Properties) {
        ## Copy over the provided properties hash
        foreach ($pk in $Properties.Keys) {
            $rProperties.$pk = $Properties[$pk]
        }
    }
    if ($Tags) {
        ## Then add any tags
        $tagsList = New-Object System.Collections.ArrayList
        foreach ($tk in $Tags.Keys) {
            $t = @{ Key = $tk }
            $tv = $Tags[$tk]
            $t.Value = $tv
            $tagsList += $t
        }
        $rProperties.Tags = $tagsList
    }

    ## Resource Attributes
    if ($DeletionPolicy) {
        $r.DeletionPolicy = $DeletionPolicy
    }
    if ($Metadata) {
        $r.Metadata = $Metadata
    }
    if ($DependsOn) {
        $r.DependsOn = $DependsOn
    }
    if ($PropertiesBlock) {
        & $PropertiesBlock
    }


    if ($Condition) {
        $r.Condition = $Condition
    }
    if ($rProperties -and $rProperties.Count) {
        $r.Properties = $rProperties
    }

    $tResources.Add($ResourceName, $r)
}
Set-Alias -Name Res-Custom -Value Add-CfnCustomResource
