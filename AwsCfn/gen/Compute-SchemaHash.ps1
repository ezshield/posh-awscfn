$schema = "$PSScriptRoot\CloudFormationV1.schema"
$bytes = [System.IO.File]::ReadAllBytes($schema)
$sha = [System.Security.Cryptography.SHA256]::Create()
$hash = $sha.ComputeHash($bytes)
$hashStr = [System.BitConverter]::ToString($hash).Replace('-', '')

$hashStr

