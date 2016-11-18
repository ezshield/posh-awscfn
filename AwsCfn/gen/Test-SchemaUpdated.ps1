
$cfnSchemaUrl = 'http://vstoolkit.amazonwebservices.com/CloudFormationSchema/CloudFormationV1.schema'
$schema = "$PSScriptRoot\CloudFormationV1.schema"
ren $schema "$schema.OLD"

Invoke-WebRequest $cfnSchemaUrl -OutFile $schema
$oldHash = Get-Content "$schema.sha256"
$newHash = .\Compute-SchemaHash.ps1

if ($oldHash -ne $newHash) {
    $msg = "CloudFormation Schema has been UPDATED!"
    Write-Host $msg
    Write-Host "Here are the changes..."
    Write-Host "*******************************************************************"
    fc.exe "$schema.OLD" $schema
}
else {
    $msg = "Cloudormation Schema is still the same"
    Write-Host $msg
}

$slackWebHook = $env:SLACK_WEBHOOK
Invoke-WebRequest -Uri $slackWebHook -Method Post -Body "payload={`"text`": `"$msg`" }"
