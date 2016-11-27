$PUB_SPEC_DIR = "$PSScriptRoot\pub" ## Folder where files are published
$PUB_RES_SPEC_FILE = "$PUB_SPEC_DIR\CfnResSpec.json"
$PUB_RES_SPEC_DOCS_FILE = "$PUB_SPEC_DIR\CfnResSpecDocs.json"

$GEN_DIR = "$PSScriptRoot\AwsCfn\gen"
$GEN_PROPTYPE_CMDLETS_DIR = "$GEN_DIR\proptypes"
$GEN_RESTYPE_CMDLETS_DIR = "$GEN_DIR\restypes"

$PRIMITIVE_TYPE_MAP = @{
    string    = "CfnParam[string]"
    long      = "CfnParam[long]"
    integer   = "CfnParam[int]"
    double    = "CfnParam[double]"
    boolean   = "CfnParam[bool]"
    timestamp = "CfnParam[datetime]"
    json      = "CfnParam[object]" ## Create CfnJsonParam
}

. "$PSScriptRoot\CfnResSpecDocParser.ps1"

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
    ## By iterating on the properties of the virtual
    ## .PSObject we preserve the property order
    foreach ($pn in $obj.PSObject.Properties.Name) {
        $p = Get-Member -InputObject $obj -Name $pn
        if ($p.TypeName -eq [psobject].FullName) {
            $ret[$p.Name] = ConvertFrom-PSObject $obj.($p.Name)
        }
        else {
            $ret[$p.Name] = $obj.($p.Name)
        }
    }
    $ret
}


if (-not (Test-Path -PathType Container $GEN_PROPTYPE_CMDLETS_DIR)) {
    mkdir -Force $GEN_PROPTYPE_CMDLETS_DIR
}
if (-not (Test-Path -PathType Container $GEN_RESTYPE_CMDLETS_DIR)) {
    mkdir -Force $GEN_RESTYPE_CMDLETS_DIR
}


$resSpecRaw = [System.IO.File]::ReadAllText($PUB_RES_SPEC_FILE)
$resDocsRaw = [System.IO.File]::ReadAllText($PUB_RES_SPEC_DOCS_FILE)

$resSpec = ConvertFrom-Json $resSpecRaw
$resDocs = ConvertFrom-Json $resDocsRaw

$resSpecVersion = $resSpec.ResourceSpecificationVersion
$resDocsVersion = $resDocs.ResourceSpecificationVersion

$propTypeNames = $resSpec.PropertyTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$resTypeNames = $resSpec.ResourceTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name

        ## Hard-coded LIMITS during dev/testing
        $propTypeNames = $propTypeNames[0..5]
        $resTypeNames = $resTypeNames[0..5]

Write-Host "Found Resource Specification [v$($resSpecVersion)]"
Write-Host "Found Resource Specification DOCS [v$($resDocsVersion)]"

Write-Host "Processing [$($propTypeNames.Count)] Property Types"
Write-Host "Processing [$($resTypeNames.Count)] Resource Types"


function Export-PropertyTypeCmdlets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$ResSpec,
        [Parameter(Mandatory)]
        [psobject]$ResDocs,

        [scriptblock]$Filter,# = { $_.Name -cmatch 'Tag' },
        [switch]$ForceGenerate,
        [string]$OutDir=$GEN_PROPTYPE_CMDLETS_DIR,

        ## Shared digester Used to compute SHA256 hashes
        $sha = [System.Security.Cryptography.SHA256]::Create()
    )

    $propTypes = $ResSpec.PropertyTypes | Get-Member -MemberType NoteProperty
    ## Filter Prop Types
    if ($Filter) {
        $propTypes = $propTypes | ? $Filter
    }

    $indentRegex = New-Object regex('^','multiline')

    foreach ($propType in $propTypes) {
        Write-Host "Processing Property Type [$($propType.Name)]"
        $specJson = $propType | ConvertTo-Json -Depth 100 -Compress
        $specHash = [BitConverter]::ToString($sha.ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($specJson))).Replace('-','')

        ## Compute the prop type *class name*
        ##  e.g.  AWS::ApiGateway::Deployment.StageDescription
        ##    ->  ApiGateway_Deployment__StageDescription
        $className = $propType.Name
        $className = $className -replace '^AWS::',''
        $className = $className -replace '\.','__'
        $className = $className -replace '::','_'

        ## Compute the property and class *group names* which are like namespaces
        ## for related property types, that may refer to each other in the child
        ## parameter section without a fully-qualified name
        ##  e.g.  AWS::ApiGateway::Deployment.StageDescription
        ##    ->  Prop Group:  AWS::ApiGateway::Deployment
        ##    ->  Class Group:  ApiGateway_Deployment
        $propGroupName = $propType.Name
        $propGroupName = $propGroupName -replace '\..+',''

        $classGroupName = $propGroupName
        $classGroupName = $classGroupName -replace '^AWS::',''
        $classGroupName = $classGroupName -replace '::','_'

        ## Compute the prop type *cmdlet name*
        ##  e.g.  AWS::ApiGateway::Deployment.StageDescription
        ##    ->  ApiGateway-Deployment_StageDescription
        $cmdletName = $propType.Name
        $cmdletName = $cmdletName -replace '^AWS::',''
        $cmdletName = $cmdletName -replace '\.','_'
        $cmdletName = $cmdletName -replace '::','-'


        ## Compute the cmdlet def and related files
        $specJsonPath = "$OutDir\$cmdletName-spec.json"
        $specMetaPath = "$OutDir\$cmdletName-spec.meta"
        $cmdletPath   = "$OutDir\$cmdletName.ps1"

        ## Load up an existing Spec Meta to inspect any prior meta data that's
        ## carried forward like Created On Date and comparison of the Hash
        $specMeta = [ordered]@{}
        if ((Test-Path $cmdletPath) -and (Test-Path $specMetaPath)) {
            $specMetaRaw = [System.IO.File]::ReadAllText($specMetaPath)
            $specMeta = ConvertFrom-PSObjectToHashtable (ConvertFrom-Json $specMetaRaw)

            ## See if we can skip this Property Type generation
            if ((-not $ForceGenerate) -and ($specMeta.SpecHash -eq $specHash)) {
                Write-Host "    NO CHANGES DETECTED; SKIPPING [$($propType.Name)][$cmdletName]"
                continue
            }
        }

        ## Start updating the Spec Meta
        ## Data to be persisted later on
        $specMeta.PropertyTypeName = $propType.Name
        $specMeta.CmdletName = $cmdletName
        if (-not $specMeta.CreatedOn) {
            $specMeta.CreatedOn = [datetime]::Now
            $specMeta.CreatedFrom = $resSpecVersion
        }
        $specMeta.UpdatedOn = [datetime]::Now
        $specMeta.UpdatedFrom = $resSpecVersion
        $specMeta.SpecHash = $specHash

        ## Resolve DOCS details
        $specDef = $ResSpec.PropertyTypes.($propType.Name)
        $specDoc = $ResDocs.PropertyTypes.($propType.Name)

        ## Assemble Doc Details for main prop type
        $specDocSynopsis = ""
        $specDocMainLink = ""
        if ($specDoc.DocumentationSummary) {
            $specDocSynopsis = ".SYNOPSIS`r`n$($specDoc.DocumentationSummary)`r`n"
        }
        if ($specDoc.DocumentationUrl) {
            $specDocSynopsis += "`r`nFor more details, see:  $($specDoc.DocumentationUrl)`r`n"
            $specDocMainLink = ".LINK`r`n$($specDoc.DocumentationUrl)"
        }

        ## Process the child property params and assemble Doc Details
        ## as well as the corresponding cmdlet param processing logic
        $specDocParamInfos = ""
        $specDocParamLinks = ""
        $cmdletParams = ""
        $cmdletDetail = ""
        foreach ($p in $specDef.Properties.PSObject.Properties) {
            $pName = $p.Name
            $pSpec = $specDef.Properties.$pName
            $pDocs = $specDoc.Properties.$pName
            if ($pDocs.DocumentationSummary) {
                $specDocParamInfos += ".PARAMETER $($pName)`r`n$($pDocs.DocumentationSummary)`r`n"
                if ($pSpec.Required) {
                    $specDocParamInfos += "`r`Required:  $($pSpec.Required)`r`n"
                }
                if ($pSpec.UpdateType) {
                    $specDocParamInfos += "`r`nUpdateType:  $($pSpec.UpdateType)`r`n"
                }
            }
            if ($pDocs.DocumentationUrl) {
                $specDocParamInfos += "`r`nFor more details, see:  $($pDocs.DocumentationUrl)`r`n"
                $specDocParamLinks += ".LINK`r`n$($pDocs.DocumentationUrl)`r`n"
            }
            $specDocParamInfos += "`r`n"

            ## Details of the Property Specification:
            ##    http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification-format.html#cfn-resource-specification-format-propertytypes
            if ($pSpec.Required) {
                $cmdletParams += "[Parameter(Mandatory)]`r`n"
            }
            else {
                $cmdletParams += "[Parameter()]`r`n"
            }

            ## Resolve the strict type
            if ($pSpec.PrimitiveType) {
                ## One of:  String, Long, Integer, Double, Boolean, Timestamp or Json
                $primType = $pSpec.PrimitiveType.ToLower()
                if (-not $PRIMITIVE_TYPE_MAP.ContainsKey($primType)) {
                    Write-Warning "UNKNOWN Primitive Type [$($primType)]; defaulting to JSON"
                    $primType = "json"
                }
                $primType = $PRIMITIVE_TYPE_MAP[$primType]
                $cmdletParams += "[$primType]`r`n"
            }
            else {
                if ($pSpec.Type -ieq 'List') {
                    if ($pSpec.PrimitiveItemType) {
                        $primType = $pSpec.PrimitiveItemType.ToLower()
                        if (-not $PRIMITIVE_TYPE_MAP.ContainsKey($primType)) {
                            Write-Warning "UNKNOWN Primitive Item Type [$($primType)]; defaulting to JSON"
                            $primType = "json"
                        }
                        $cmdletParams += "[CfnParam[$primType[]]]`r`n"
                    }
                    else {
                        $cmdletParams += "[CfnParam[AwsCfn_$($classGroupName)__$($pSpec.ItemType)[]]]`r`n"
                    }
                }
                elseif ($pSpec.Type -ieq 'Map') {
                    if ($pSpec.PrimitiveItemType) {
                        $primType = $pSpec.PrimitiveItemType.ToLower()
                        if (-not $PRIMITIVE_TYPE_MAP.ContainsKey($primType)) {
                            Write-Warning "UNKNOWN Primitive Item Type [$($primType)]; defaulting to JSON"
                            $primType = "json"
                        }
                        $cmdletParams += "[CfnMapParam[$primType]]`r`n"
                    }
                    else {
                        $cmdletParams += "[CfnMapParam[AwsCfn_$($classGroupName)__$($pSpec.ItemType)]]`r`n"
                    }
                }
                else {
                    $cmdletParams += "[CfnParam[AwsCfn_$($classGroupName)__$($pSpec.ItemType)]]`r`n"
                }
            }
            $pSpecHash = ConvertFrom-PSObjectToHashtable $pSpec
            $pSpecHash.Remove('Documentation')
            $cmdletParams += "`$$pName ## $($pSpecHash | ConvertTo-Json -Compress)`r`n"
        }

        ## Start assembling the cmdlet definition
        $cmdletBody = @"
<#
    *****************************************************************************
    Property Type - [$($propType.Name)]
    Spec Hash Sig - [$($specHash)] ($($sha.GetType().Name))
    CreatedOn:  $($specMeta.CreatedOn -f 'yyyy-MM-dd HH:mm:ss') ($($specMeta.CreatedFrom))
    UpdatedOn:  $($specMeta.UpdatedOn -f 'yyyy-MM-dd HH:mm:ss') ($($specMeta.UpdatedFrom))
 #>

class AwsCfn_$($className)
    : System.Collections.Specialized.OrderedDictionary {
    AwsCfn_$($className)() { }
    AwsCfn_$($className)([hashtable]`$Value)
        : base(`$Value) { }
}

function New-AwsCfn$($cmdletName) {
<#
$specDocSynopsis
$specDocParamInfos
$specDocMainLink
$specDocParamLinks
#>
    [CmdletBinding()]
    [OutputType([AwsCfn_$($className)])]
    param(
$($indentRegex.Replace($cmdletParams, '        '))
    )

$($indentRegex.Replace($cmdletDetail, '    '))
}

"@

        ## Save the cmdlet def
        [System.IO.File]::WriteAllText($cmdletPath, $cmdletBody)
        ## Save some meta data so can carry some info forward in future generation
        ## or so we don't have to regenerate in the future if there are no changes
        [System.IO.File]::WriteAllText($specMetaPath, ($specMeta | ConvertTo-Json))

    }
}

Export-PropertyTypeCmdlets -Verbose -ResSpec $resSpec -ResDocs $resDocs `
        -ForceGenerate #-Filter { $_.Name -cmatch 'Tag' }
