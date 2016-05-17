
ipmo AWSPowerShell

<#
These routines can be used to define default set of AWS access credentials and region
parameters in the current context (i.e. PS Session) and resolve these as needed.
#>

function Use-AwsBaseParams {
    param(
        [string]$DefaultProfileName,
        [string]$DefaultRegion,
        [string]$ProfileName,
        [string]$Region
    )

    $resolveAwsResources = [ordered]@{
        awsBaseParams = [ordered]@{
            ProfileName = $(if($ProfileName){$ProfileName}else{$DefaultProfileName})
            Region      = $(if($Region     ){$Region     }else{$DefaultRegion     })
        }
    }
    Set-Variable -Name resolveAwsResources -Scope 1 -Value $resolveAwsResources

    Write-Debug "AWS Base Params: $($resolveAwsResources.awsBaseParams | ConvertTo-Json -Compress)"
}

function Resolve-AwsBaseParams {
    param(
        [Parameter(Position=0)]
        [string]$ProfileName,
        [Parameter(Position=1)]
        [string]$Region
    )

    $awsBaseParams = [ordered]@{
        ProfileName = $ProfileName
        Region      = $Region
    }
    if (-not $ProfileName -and $resolveAwsResources.awsBaseParams.ProfileName) {
        $awsBaseParams.ProfileName = $resolveAwsResources.awsBaseParams.ProfileName
    }
    if (-not $Region -and $resolveAwsResources.awsBaseParams.Region) {
        $awsBaseParams.Region = $resolveAwsResources.awsBaseParams.Region
    }

    Write-Debug "Resolved AWS BaseParams:  $($awsBaseParams | ConvertTo-Json -Compress)"

    $awsBaseParams
}