
## AWS CFN Resource Specification Format:
##    http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification-format.html

$resSpecFile  = "$PSScriptRoot\CloudFormationResourceSpecification.json"
$genPropTypes = "$PSScriptRoot\gen-proptypes"
$genResTypes  = "$PSScriptRoot\gen-restypes"

if (-not (Test-Path $genPropTypes -PathType Container)) {
    mkdir $genPropTypes
}
if (-not (Test-Path $genResTypes -PathType Container)) {
    mkdir $genResTypes
}


$resSpecRaw = [System.IO.File]::ReadAllText($resSpecFile)
$resSpec = ConvertFrom-Json $resSpecRaw

$resSpecVersion = $resSpec.ResourceSpecificationVersion
$resSpecPropTypes = $resSpec.PropertyTypes | Get-Member -MemberType NoteProperty | select Name
$resSpecResTypes = $resSpec.ResourceTypes | Get-Member -MemberType NoteProperty | select Name

<#
Convenience routine to convert a custom object, such as that generated when converting from JSON, into an Ordered Hashtable
#>
function ConvertFrom-PSObjectToHashtable {
    param(
        [Parameter(Mandatory, Position=0)]
        [psobject]$obj,
        [Parameter(Position=1)]
        [bool]$Ordered=$true
    )
    $ret = [ordered]@{}
    foreach ($p in (Get-Member -InputObject $obj -MemberType NoteProperty)) {
        if ($p.TypeName -eq [psobject].FullName) {
            $ret[$p.Name] = ConvertFrom-PSObject $obj.($p.Name)
        }
        else {
            $ret[$p.Name] = $obj.($p.Name)
        }
    }
    $ret
}

Write-Output "Processing Resource Specification Version [$resSpecVersion]"
Write-Output "  * Found [$($resSpecPropTypes.Count)] Property Types"
Write-Output "  * Found [$($resSpecResTypes.Count)] Resource Types"

## Used to compute SHA256 hashes
$sha = [System.Security.Cryptography.SHA256]::Create()

function Export-PropertyTypeCmdlets {
    [CmdletBinding()]
    param(
        [scriptblock]$Filter = { $_.Name -cmatch 'Tag' },
        [switch]$ForceGenerate
    )

    ## Filter Prop Types
    if ($Filter) {
        $resSpecPropTypes = $resSpecPropTypes | ? $Filter
    }

    foreach ($propType in $resSpecPropTypes) {
        Write-Verbose "Processing Property Type [$($propType.Name)]"
        $propSpec = $resSpec.PropertyTypes.($propType.Name)
        $specJson = $resSpec.PropertyTypes.($propType.Name) | ConvertTo-Json -Depth 100 -Compress
        $specHash = [BitConverter]::ToString($sha.ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($specJson))).Replace('-','')

        ## Compute the prop type *cmdlet name"
        $cmdletName = $propType.Name
        $cmdletName = $cmdletName -replace '^AWS::',''
        $cmdletName = $cmdletName -replace '::','-'
        $cmdletName = $cmdletName -replace '\.','_'

        ## Compute the cmdlet def and related files
        $specJsonPath = "$genPropTypes\$cmdletName-spec.json"
        $specMetaPath = "$genPropTypes\$cmdletName-spec.meta"
        $cmdletPath   = "$genPropTypes\$cmdletName.ps1"

        ## Load up an existing Spec Meta to inspect any prior meta data that's
        ## carried forward like Created On Date and comparison of the Hash
        $specMeta = @{}
        if ((Test-Path $cmdletPath) -and (Test-Path $specMetaPath)) {
            $specMetaRaw = [System.IO.File]::ReadAllText($specMetaPath)
            $specMeta = ConvertFrom-PSObjectToHashtable (ConvertFrom-Json $specMetaRaw)

            ## See if we can skip this Property Type generation
            if ((-not $ForceGenerate) -and ($specMeta.SpecHash -eq $specHash)) {
                Write-Warning "    NO CHANGES DETECTED; SKIPPING [$($propType.Name)][$cmdletName]"
                continue
            }
        }

        ## Start updating the Spec Meta
        ## Data to be persisted later on
        $specMeta.PropertyTypeName = $propType.Name
        $specMeta.CmdletName = $cmdletName
        $specMeta.UpdatedOn = [datetime]::Now
        $specMeta.UpdatedFrom = $resSpecVersion
        if (-not $specMeta.CreatedOn) {
            $specMeta.CreatedOn = [datetime]::Now
            $specMeta.CreatedFrom = $resSpecVersion
        }
        $specMeta.SpecHash = $specHash

        ## Start assembling the cmdlet definition
        $cmdletBody = @"
<#
    *****************************************************************************
    Property Type - [$propTypeName]
    Spec Hash Sig - [$specHash] ($($sha.GetType().Name))
    CreatedOn:  $($specMeta.CreatedOn -f 'yyyy-MM-dd HH:mm:ss') ($($specMeta.CreatedFrom))
    UpdatedOn:  $($specMeta.UpdatedOn -f 'yyyy-MM-dd HH:mm:ss') ($($specMeta.UpdatedFrom))
    #>

function New-AwsCfn$cmdletName {
<#
.SYNOPSIS

#>
    [CmdletBinding()]
    param(
    )
}

"@

        ## Save the cmdlet def
        [System.IO.File]::WriteAllText($cmdletPath, $cmdletBody)
        ## Save some meta data so can carry some info forward in future generation
        ## or so we don't have to regenerate in the future if there are no changes
        [System.IO.File]::WriteAllText($specMetaPath, ([ordered]@{
            PropertyTypeName = $($specMeta.PropertyTypeName)
            CmdletName       = $($specMeta.CmdletName)
            CreatedOn        = $($specMeta.CreatedOn)
            CreatedFrom      = $($specMeta.CreatedFrom)
            UpdatedOn        = $($specMeta.UpdatedOn)
            UpdatedFrom      = $($specMeta.UpdatedFrom)
            SpecHash         = $($specMeta.SpecHash)
        } | ConvertTo-Json))

    }
}

#Export-PropertyTypeCmdlets -Verbose -ForceGenerate
