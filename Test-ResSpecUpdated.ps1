
$GEN_SPEC_DIR = "$PSScriptRoot\gen" ## Folder where files are generated
$PUB_SPEC_DIR = "$PSScriptRoot\pub" ## Folder where files are published

$GEN_RES_SPEC_FILE = "$GEN_SPEC_DIR\CfnResSpec.json"
$GEN_RES_SPEC_DOCS_FILE = "$GEN_SPEC_DIR\CfnResSpecDocs.json"
$PUB_RES_SPEC_FILE = "$PUB_SPEC_DIR\CfnResSpec.json"
$PUB_RES_SPEC_DOCS_FILE = "$PUB_SPEC_DIR\CfnResSpecDocs.json"

. "$PSScriptRoot\CfnResSpecDocParser.ps1"


function Compute-FileHash {
    param([string[]]$filepaths)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        foreach ($fp in $filepaths) {
            if (-not (Test-Path -PathType Leaf $fp)) {
                Write-Verbose "Skipping hash computation of non-existent file [$fp]"
                continue
            }
            $bytes = [System.IO.File]::ReadAllBytes($fp)
            $hash = $sha.ComputeHash($bytes)
            $hashStr = [System.BitConverter]::ToString($hash).Replace('-', '')
            $hashStr > "$($fp).sha256"
        }
    }
    finally {
        $sha.Dispose()
    }
}


if (-not (Test-Path -PathType Container $GEN_SPEC_DIR)) {
    mkdir -Force $GEN_SPEC_DIR
}
if (-not (Test-Path -PathType Container $PUB_SPEC_DIR)) {
    mkdir -Force $PUB_SPEC_DIR
}


## This will pull down the latest Resource Specificion JSON file and generate a Docs JSON file
$specDocs = Export-ResourceSpecificationDocItems -ResSpecFile $GEN_RES_SPEC_FILE -Verbose |
        ConvertTo-Json -Depth 100
$specDocs -replace '    ',' ' > $GEN_RES_SPEC_DOCS_FILE

Compute-FileHash @($GEN_RES_SPEC_FILE, $GEN_RES_SPEC_DOCS_FILE)
$newSpecHash = [System.IO.File]::ReadAllText("$($GEN_RES_SPEC_FILE).sha256")
$newDocsHash = [System.IO.File]::ReadAllText("$($GEN_RES_SPEC_DOCS_FILE).sha256")

$oldSpecHash = ""
if (Test-Path $PUB_RES_SPEC_FILE) {
    $oldSpecHash = [System.IO.File]::ReadAllText("$($PUB_RES_SPEC_FILE).sha256")
}
$oldDocsHash = ""
if (Test-Path $PUB_RES_SPEC_DOCS_FILE) {
    $oldDocsHash = [System.IO.File]::ReadAllText("$($PUB_RES_SPEC_DOCS_FILE).sha256")
}

if ($newSpecHash -ne $oldSpecHash) {
    $specMesg = "CloudFormation Resource Specification - CHANGES HAVE BEEN FOUND!"
    $specDiff =  "HERE ARE THE CHANGES:"
    $specDiff += "****************************************************************"
    $specDiff += & fc.exe $PUB_RES_SPEC_FILE $GEN_RES_SPEC_FILE
    copy -Force "$GEN_RES_SPEC_FILE"        "$PUB_RES_SPEC_FILE"
    copy -Force "$GEN_RES_SPEC_FILE.sha256" "$PUB_RES_SPEC_FILE.sha256"
}
else {
    $specMesg = "CloudFormation Resource Specification - NO changes found"
    $specDiff = ""
    del -Force "$GEN_RES_SPEC_FILE"
    del -Force "$GEN_RES_SPEC_FILE.sha256"
}
Write-Host $specMesg
#Write-Host $specDiff

if ($newDocsHash -ne $oldDocsHash) {
    $docsMesg = "CloudFormation Resource Specification DOCS - CHANGES HAVE BEEN FOUND!"
    $docsDiff =  "HERE ARE THE CHANGES:"
    $docsDiff += "****************************************************************"
    $docsDiff += & fc.exe $PUB_RES_SPEC_DOCS_FILE $GEN_RES_SPEC_DOCS_FILE
    copy -Force "$GEN_RES_SPEC_DOCS_FILE"        "$PUB_RES_SPEC_DOCS_FILE"
    copy -Force "$GEN_RES_SPEC_DOCS_FILE.sha256" "$PUB_RES_SPEC_DOCS_FILE.sha256"
}
else {
    $docsMesg = "CloudFormation Resource Specification DOCS - NO changs found"
    $docsDiff = ""
    del -Force "$GEN_RES_SPEC_DOCS_FILE"
    del -Force "$GEN_RES_SPEC_DOCS_FILE.sha256"
}
Write-Host $docsMesg
#Write-Host $docsDiff

$slackWebHook = $env:SLACK_WEBHOOK
if ($slackWebHook) {
    Write-Host "Sending notifications..."
    $ret = Invoke-WebRequest -Uri $slackWebHook -Method Post -Body "payload={`"text`": `"$specMesg`" }"
    if (200 -eq $ret.StatusCode) {
        Write-Host "Success"
    }
    else {
        Write-Host "Failure: ($($ret.StatusCode)) [$($ret.StatusDescription)]"
    }

    $ret = Invoke-WebRequest -Uri $slackWebHook -Method Post -Body "payload={`"text`": `"$docsMesg`" }"
    if (200 -eq $ret.StatusCode) {
        Write-Host "Success"
    }
    else {
        Write-Host "Failure: ($($ret.StatusCode)) [$($ret.StatusDescription)]"
    }
}
