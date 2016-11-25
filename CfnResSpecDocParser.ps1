
$AWS_CFN_RES_SPEC_DOC_URL = "http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html"
$DEFAULT_REGION_KEY = "US East (N. Virginia)"

function Resolve-ResourceSpecificationLinks {
<#
.SYNOPSIS
Pulls down the starting page of the Resource Specification documentation from the CFN User's Guide and
parses out the locations of the different specs (single file and ZIP of multi files) for each AWS Region.
#>
    param(
        [string]$DocUrl=$AWS_CFN_RES_SPEC_DOC_URL
    )

    $docResp = Invoke-WebRequest -Uri $AWS_CFN_RES_SPEC_DOC_URL
    $docHtml = $docResp.ParsedHtml

    $docTableDiv = $docHtml.getElementsByTagName('div') | ? { $_.className -eq 'table-contents' } | select -First 1
    $docTableBody = $docTableDiv.getElementsByTagName('tbody') | select -First 1
    $docRegionRows = $docTableBody.getElementsByTagName('tr')

    $specLinksByRegion = [ordered]@{}
    foreach ($tr in $docRegionRows) {
        $regionName = $tr.children[0].innerText
        $singleFileLink = $tr.children[1].getElementsByTagName('a')[0]
        $multiFilesLink = $tr.children[2].getElementsByTagName('a')[0]

        $specLinksByRegion.$regionName = [ordered]@{
            SingleFileName = $singleFileLink.innerText
            SingleFileLink = $singleFileLink.attributes['href'].value
            MultiFilesName = $multiFilesLink.innerText
            MultiFilesLink = $multiFilesLink.attributes['href'].value
        }
    }

    return $specLinksByRegion
}

function ConvertFrom-PropertyTypeHtmlDocs {
<#
.SYNOPSIS
Pulls down the documentation page of a single Property Type from the CFN User's
Guide and parses out the first paragraph of the main description of the Property
Type, as well as the first paragraph of the description of any of its sub-properties.
#>
    param(
        [string]$DocUrl
    )
    $docResult = Invoke-WebRequest -Uri $DocUrl
    $docHtml = $docResult.ParsedHtml

    $docTitle = $docHtml.getElementsByTagName('h1')[0].innerText

    $mainTitle = $docHtml.getElementsByTagName("div") | ? { $_.className -eq 'titlepage' } | select -First 1
    $mainDesc = $mainTitle.nextSibling.innerText

    $propDefList = $docHtml.getElementsByTagName("dl")[0]
    $propDescs = [ordered]@{}
    foreach ($dt in $propDefList.getElementsByTagName("dt")) {
        $propKey = $dt.innerText
        $propVal = $dt.nextSibling.getElementsByTagName("p")[0].innerText
        $propDescs[$propKey] = $propVal
    }

    $ret = New-Object psobject
    $ret | Add-Member -NotePropertyMembers ([ordered]@{
        MainDescription      = $mainDesc
        PropertyDescriptions = $propDescs
    })
    return $ret
}

function ConvertFrom-ResourceTypeHtmlDocs {
<#
.SYNOPSIS
Pulls down the documentation page of a single Resource Type from the CFN User's
Guide and parses out the first paragraph of the main description of the Resource
Type, as well as the first paragraph of the description of any of its sub-properties.
#>
    param(
        [string]$DocUrl
    )
    $docResult = Invoke-WebRequest -Uri $DocUrl
    $docHtml = $docResult.ParsedHtml

    $docTitle = $docHtml.getElementsByTagName('h1')[0].innerText

    $mainTitle = $docHtml.getElementsByTagName("div") | ? { $_.className -eq 'titlepage' } | select -First 1
    $mainDesc = $mainTitle.nextSibling.innerText

    $propDefList = $docHtml.getElementsByTagName("dl")[0]
    $propDescs = [ordered]@{}
    foreach ($dt in $propDefList.getElementsByTagName("dt")) {
        $propKey = $dt.innerText
        $propVal = $dt.nextSibling.getElementsByTagName("p")[0].innerText
        $propDescs[$propKey] = $propVal
    }

    $ret = New-Object psobject
    $ret | Add-Member -NotePropertyMembers ([ordered]@{
        MainDescription      = $mainDesc
        PropertyDescriptions = $propDescs
    })
    return $ret
}

function Export-PropertyTypeDocItems {
<#
Given a Resource Specification description object (e.g. parsed out of JSON),
extracts all the Property Types and extracts all the summary
documentation for each Property Type and each of its sub-properties.
#>
    param(
        [object]$ResourcesSpecification,
        [string[]]$PropTypeNames
    )

    $propTypeDocs = [ordered]@{}
    $index = 0
    foreach ($propTypeName in $PropTypeNames) {
        ++$index
        Write-Verbose "Processing Property Type (#$index) [$propTypeName]"
        $propTypeSpec = $ResourcesSpecification.PropertyTypes.$propTypeName
        $docItems = ConvertFrom-PropertyTypeHtmlDocs -DocUrl $propTypeSpec.Documentation

        $docJson = [ordered]@{
            Name = $propTypeName
            Index = $index
            DocumentationUrl = $propTypeSpec.Documentation
            DocumentationSummary = $docItems.MainDescription
            Properties = [ordered]@{}
        }

        foreach ($p in ($propTypeSpec.Properties | Get-Member -MemberType NoteProperty | select -ExpandProperty Name)) {
            $docJson.Properties.$p = [ordered]@{
                Name = $p
                DocumentationUrl = $propTypeSpec.Properties.$p.Documentation
                DocumentationSummary = $docItems.PropertyDescriptions[$p]
            }
        }

        $propTypeDocs[$propTypeName] = $docJson
    }
    return $propTypeDocs
}

function Export-ResourceTypeDocItems {
<#
Given a Resource Specification description object (e.g. parsed out of JSON),
extracts all the Resource Types and extracts all the summary
documentation for each Resource Type and each of its sub-properties.
#>    param(
        [object]$ResourcesSpecification,
        [string[]]$ResTypeNames
    )

    $resTypeDocs = [ordered]@{}
    $index = 0
    foreach ($resTypeName in $ResTypeNames) {
        ++$index
        Write-Verbose "Processing Resource Type (#$index) [$resTypeName]"
        $resTypeSpec = $ResourcesSpecification.ResourceTypes.$resTypeName
        $docItems = ConvertFrom-ResourceTypeHtmlDocs -DocUrl $resTypeSpec.Documentation

        $docJson = [ordered]@{
            Name = $resTypeName
            Index = $index
            DocumentationUrl = $resTypeSpec.Documentation
            DocumentationSummary = $docItems.MainDescription
            Properties = [ordered]@{}
        }

        foreach ($p in ($resTypeSpec.Properties | Get-Member -MemberType NoteProperty | select -ExpandProperty Name)) {
            $docJson.Properties.$p = [ordered]@{
                Name = $p
                DocumentationUrl = $resTypeSpec.Properties.$p.Documentation
                DocumentationSummary = $docItems.PropertyDescriptions[$p]
            }
        }

        $resTypeDocs.$resTypeName = $docJson
    }
    return $resTypeDocs
}

function Export-ResourceSpecificationDocItems {
<#
.SYNOPSIS
Resolves the current AWS CloudFormationb Resource Specification and extracts
the current summary documentation for each Property Type and Resource Type.
#>
    [CmdletBinding()]
    param(
        [string]$ResSpecFile="$PSScriptRoot\CfnResSpec.json",
        [string]$DocUrl=$AWS_CFN_RES_SPEC_DOC_URL,
        [string]$DocRegion=$DEFAULT_REGION_KEY,
        [switch]$ForceDocFetch
    )

    if ($ForceDocFetch -or -not (Test-Path $ResSpecFile)) {
        Write-Verbose "Fetching latest Resource Specification for Region [$DocRegion]"
        $resSpecLinks = Resolve-ResourceSpecificationLinks -DocUrl $DocUrl
        Write-Verbose "  saving to local file [$ResSpecFile]"
        Invoke-WebRequest $resSpecLinks[$DocRegion].SingleFileLink -OutFile $ResSpecFile
    }
    else {
        Write-Verbose "Found and using locally cached Resource Specification [$ResSpecFile]"
    }

    $resSpecRaw = [System.IO.File]::ReadAllText($ResSpecFile)
    $resSpec = ConvertFrom-Json $resSpecRaw
    
    $resSpecVersion = $resSpec.ResourceSpecificationVersion
    $propTypeNames = $resSpec.PropertyTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    $resTypeNames = $resSpec.ResourceTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    
    Write-Verbose "Found [$($propTypeNames.Count)] Property Types"
    Write-Verbose "Found [$($resTypeNames.Count)] Resource Types"

    $propTypeDocs = Export-PropertyTypeDocItems -ResourcesSpecification $resSpec -PropTypeNames $propTypeNames
    $resTypeDocs = Export-ResourceTypeDocItems -ResourcesSpecification $resSpec -ResTypeNames $resTypeNames
    
    return [ordered]@{
        ResourceSpecificationVersion = $resSpecVersion
        ResourceSpecificationDocumentationUrl = $DocUrl
        PropertyTypes = $propTypeDocs
        ResourceTypes = $resTypeDocs
    }
}

## For testing:
#Export-ResourceSpecificationDocItems -Verbose | ConvertTo-Json -Depth 100