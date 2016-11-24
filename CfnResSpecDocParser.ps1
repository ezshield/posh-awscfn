
$AWS_CFN_RES_SPEC_DOC_URL = "http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html"
$DEFAULT_REGION_KEY = "US East (N. Virginia)"

function Resolve-ResourceSpecificationLinks {
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

    $specLinksByRegion
}

function ConvertFrom-PropertyTypeHtmlDocs {
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
    $ret
}

function ConvertFrom-ResourceTypeHtmlDocs {
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
    $ret
}

function Export-PropertyTypeDocItems {
    param(
        [object]$ResourcesSpecification,
        [string[]]$PropTypeNames
    )

    $propTypeDocs = [ordered]@{}
    foreach ($propTypeName in $PropTypeNames[0..1]) {
        Write-Verbose "Processing Property Type [$propTypeName]"
        $propTypeSpec = $ResourcesSpecification.PropertyTypes.$propTypeName
        $docItems = ConvertFrom-PropertyTypeHtmlDocs -DocUrl $propTypeSpec.Documentation

        $docJson = [ordered]@{
            Name = $propTypeName
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
    $propTypeDocs
}

function Export-ResourceTypeDocItems {
    param(
        [object]$ResourcesSpecification,
        [string[]]$ResTypeNames
    )

    $resTypeDocs = [ordered]@{}
    foreach ($resTypeName in $ResTypeNames[0..1]) {
        Write-Verbose "Processing Resource Type [$resTypeName]"
        $resTypeSpec = $ResourcesSpecification.ResourceTypes.$resTypeName
        $docItems = ConvertFrom-ResourceTypeHtmlDocs -DocUrl $resTypeSpec.Documentation

        $docJson = [ordered]@{
            Name = $resTypeName
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
    $resTypeDocs
}

function Export-ResourceSpecificationDocItems {
    [CmdletBinding()]
    param(
        [string]$DocUrl=$AWS_CFN_RES_SPEC_DOC_URL,
        [string]$DocRegion=$DEFAULT_REGION_KEY,
        [switch]$ForceDocFetch
    )

    $resSpecFile = "$PSScriptRoot\CfnResSpec.json"
    if ($ForceDocFetch -or -not (Test-Path $resSpecFile)) {
        Write-Output "Fetching latest Resource Specification for Region [$DocRegion]"
        $resSpecLinks = Resolve-ResourceSpecificationLinks -DocUrl $DocUrl
        Write-Output "  saving to local file [$resSpecFile]"
        Invoke-WebRequest $resSpecLinks[$DocRegion].SingleFileLink -OutFile $resSpecFile
    }
    else {
        Write-Output "Found and using locally cached Resource Specification [$resSpecFile]"
    }

    $resSpecRaw = [System.IO.File]::ReadAllText($resSpecFile)
    $resSpec = ConvertFrom-Json $resSpecRaw
    
    $resSpecVersion = $resSpec.ResourceSpecificationVersion
    $propTypeNames = $resSpec.PropertyTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    $resTypeNames = $resSpec.ResourceTypes | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    
    $propTypeDocs = Export-PropertyTypeDocItems -ResourcesSpecification $resSpec -PropTypeNames $propTypeNames
    $resTypeDocs = Export-ResourceTypeDocItems -ResourcesSpecification $resSpec -ResTypeNames $resTypeNames
    
    Write-Output ([ordered]@{
        ResourceSpecificationVersion = $resSpecVersion
        ResourceSpecificationDocumentationUrl = $DocUrl
        PropertyTypes = $propTypeDocs
        ResourceTypes = $resTypeDocs
    } | ConvertTo-Json -Depth 100)
}

Export-ResourceSpecificationDocItems -Verbose