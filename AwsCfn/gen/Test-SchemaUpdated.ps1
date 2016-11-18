
$cfnSchemaUrl = 'http://vstoolkit.amazonwebservices.com/CloudFormationSchema/CloudFormationV1.schema'
$schema = "$PSScriptRoot\CloudFormationV1.schema"


Invoke-WebRequest $cfnSchemaUrl -OutFile $schema
$oldHash = Get-Content "$schema.sha256"
$newHash = .\Compute-SchemaHash.ps1

if ($oldHash -ne $newHash) {
    $msg = "CloudFormation Schema has been UPDATED!"
}
else {
    $msg = "Cloudormation Schema is still the same"
}

$slackWebHook = $env:SLACK_WEBHOOK
Invoke-WebRequest -Uri $slackWebHook -Method Post -Body "payload={`"text`": `"$msg`" }"
