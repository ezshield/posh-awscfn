
. $PSScriptRoot\AwsCommon.ps1

<#
The functions defined here provide convenience routines for resolving references
to various AWS resource types based on the different identifiers that are applicable
to that resource.

In most cases, a resource can at least be identified by its AWS-assigned,
resource-specific, resource ID, for example i-abc1345696 for EC2 instances
or sg-456abc123 for a security group (however, even this rule is not always
enforced, for example Key Pairs have a user-assigned name, and no ID).

Additionally, many resources have alternate unique or semi-unique identifiers,
such as a "Name" tag, which is not strictly required to be unique, but could be
as a matter of convention in an AWS root account.

Regardless, each of these "finders" will take an arbitrary string and resolve the
reference to the best of its ability in a most-specific to least-specific priority
order.

Most of the routines, will fail if there are multiple matches found, unless the
-First option flag is given which will only return the first one found (in no
guaranteed order).  Additionally, most will fail if no resource is found, unless
the -IgnoreMissing option flag is given.  So the intent is for each of these
finders to return exactly one expected and known resource.

Also, by default the finders will return just a string identifier for the found
resource.  This behavior can be altered with the -AsResource option flag which
will return the full structured type corresponding to the resource in the AWS SDK.
#>

Set-Alias findKypr Find-AwsKeyPairByRef
function Find-AwsKeyPairByRef {
<#
.PARAMETER ResourceRef
A reference to a Key Pair, either a fingerprint or key name.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
If the resource reference is ambiguous and resolve to multiple resources, an exception is thrown unless this switch is specified to return the first resource.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.KeyPairInfo],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResoureRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2KeyPair @awsBaseParams -Filters @{ Name="fingerprint"; Value=$ResoureRef }
    if (-not $res) {
        $res = Get-EC2KeyPair @awsBaseParams -Filters @{ Name="key-name"; Value=$ResoureRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve Key Pair for Fingerprint/Name [$($ResoureRef)]"
    }
    if ($res.Count -gt 1) {
        if ($First) {
            $res = $res | Select -First 1
        }
        else {
            throw "Ambiguous reference returned multiple Key Pairs"
        }
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.KeyName
    }
}

Set-Alias findZone Find-AwsHostedZoneByRef
function Find-AwsHostedZoneByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.Vpc],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    try {
        $res = Get-R53HostedZone @awsBaseParams -Id $ResourceRef -ErrorAction SilentlyContinue
        if ($res) { $res = $res.HostedZone }
    } catch {}
    if (-not $res) {
        $res = Get-R53HostedZonesByName @awsBaseParams |
            ? { ($_.Id -eq $ResourceRef) -or
                ($_.Name -eq $ResourceRef) -or
                ($_.Name -eq "$($ResourceRef).") }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve Route 53 Hosted Zone for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.Id
    }
}

Set-Alias findVpc Find-AwsVpcByRef
function Find-AwsVpcByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.Vpc],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2Vpc @awsBaseParams -Filters @{ Name="vpc-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2Vpc @awsBaseParams -Filters @{ Name="tag:Name"; Values=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve VPC for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.VpcId
    }
}

Set-Alias findVpx Find-AwsVpcPeeringConnectonByRef
function Find-AwsVpcPeeringConnectonByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.VpcPeeringConnection],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2VpcPeeringConnections @awsBaseParams -Filters @{ Name="vpc-peering-connection-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2VpcPeeringConnections @awsBaseParams -Filters @{ Name="tag:Name"; Values=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve VPX for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.VpcPeeringConnectionId
    }
}

Set-Alias findIgw Find-AwsInternetGatewayByRef
function Find-AwsInternetGatewayByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.InternetGateway],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2InternetGateway @awsBaseParams -Filters @{ Name="internet-gateway-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2InternetGateway @awsBaseParams -Filters @{ Name="tag:Name"; Values=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve IGW for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.InternetGatewayId
    }
}

Set-Alias findVgw Find-AwsVpnGatewayByRef
function Find-AwsVpnGatewayByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.VpnGateway],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2VpnGateway @awsBaseParams -Filters @{ Name="vpn-gateway-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2VpnGateway @awsBaseParams -Filters @{ Name="tag:Name"; Values=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve IGW for ID/Name [$($ResourceRef)]"
    }
    
    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.VpnGatewayId
    }
}

Set-Alias findRtt Find-AwsRouteTableByRef
function Find-AwsRouteTableByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.RouteTable],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2RouteTable @awsBaseParams `
            -Filters @{ Name="route-table-id"; Value=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2RouteTable @awsBaseParams `
                -Filters @{ Name="tag:Name"; Value=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve Route Table for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.RouteTableId
    }
}

Set-Alias findNet Find-AwsSubnetByRef
function Find-AwsSubnetByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.Subnet],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2Subnet @awsBaseParams `
            -Filters @{ Name="subnet-id"; Value=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2Subnet @awsBaseParams `
                -Filters @{ Name="tag:Name"; Value=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve Subnet for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.SubnetId
    }
}

Set-Alias findSg Find-AwsSecurityGroupByRef
function Find-AwsSecurityGroupByRef {
<#
.PARAMETER ResourceRef
A reference to the Security Group, either a unique ID, unique Group Name or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.SecurityGroup],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2SecurityGroup @awsBaseParams -Filters @{ Name="group-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2SecurityGroup @awsBaseParams -Filters @{ Name="group-name"; Values=$ResourceRef }
        if (-not $res) {
            $res = Get-EC2SecurityGroup @awsBaseParams -Filters @{ Name="tag:Name"; Values=$ResourceRef }
        }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve Security Group for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.GroupId
    }
}

Set-Alias findEni Find-AwsNetworkInterfaceByRef
function Find-AwsNetworkInterfaceByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.NetworkInterface],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [Parameter(Mandatory=$false)]
        [Alias("ProfileName")]
        [string]$ProfileName,
        [Parameter(Mandatory=$false)]
        [Alias("Region")]
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2NetworkInterface @awsBaseParams `
            -Filters @{ Name="network-interface-id"; Value=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2NetworkInterface @awsBaseParams `
                -Filters @{ Name="tag:Name"; Value=$ResourceRef }
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve ENI for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.NetworkInterfaceId
    }
}

Set-Alias findVm Find-AwsInstanceByRef
function Find-AwsInstanceByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER VmState
By default only EC2 instances in the 'running' state are returned; you can specify an alternate target state or $null to return all states.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.Instance],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [string]$VmState="running",
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $idFilter = @(@{ Name="instance-id"; Values=$ResourceRef })
    $tagFilter = @(@{ Name="tag:Name"; Values=$ResourceRef })
    if ($VmState) {
        $idFilter += @{ Name="instance-state-name"; Values=$VmState }
        $tagFilter += @{ Name="instance-state-name"; Values=$VmState }
    }

    $res = Get-EC2Instance @awsBaseParams -Filter $idFilter
    if (-not $res -or -not $res.Instances) {
        $res = Get-EC2Instance @awsBaseParams -Filter $tagFilter
    }
    if (-not $res -or -not $res.Instances) {
        if ($IgnoreMissing) {
            return $null
        }
        throw "Failed to resolve EC2 Instance for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res.Instances[0]
    }
    else {
        return $res.Instances[0].InstanceId
    }
}

Set-Alias findVol Find-AwsVolumeByRef
function Find-AwsVolumeByRef {
<#
.PARAMETER ResourceRef
A reference to the resource, either a unique ID or a Name Tag.
.PARAMETER AsResource
When specified, returns the whole resource object; otherwise just the resource identifier.
.PARAMETER First
Use this switch to return the first resource if the resource reference resolves to multiple resources.
.PARAMETER IgnoreMissing
If the resource reference does not resolve to any known resource, an exception is thrown unless this switch is specified to return null.
#>
    [OutputType([string],ParameterSetName="Default")]
    [OutputType([Amazon.EC2.Model.Volume],ParameterSetName="Resource")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ResourceRef,
        [Parameter(Mandatory=$false,ParameterSetName="Resource")]
        [switch]$AsResource,
        [switch]$First,
        [switch]$IgnoreMissing,

        ## Base Args for all AWS calls
        [string]$ProfileName,
        [string]$Region
    )

    $awsBaseParams = Resolve-AwsBaseParams $ProfileName $Region

    $res = Get-EC2Volume @awsBaseParams -Filter @{ Name="volume-id"; Values=$ResourceRef }
    if (-not $res) {
        $res = Get-EC2Volume @awsBaseParams -Filter @{ Name="tag:Name"; Values=$ResourceRef } 
    }
    if (-not $res) {
        if ($IgnoreMissing) {
            return null
        }
        throw "Failed to resolve EBS Volume for ID/Name [$($ResourceRef)]"
    }

    if ($First) {
        $res = $res | select -First 1
    }
    
    if ($AsResource.IsPresent) {
        return $res
    }
    else {
        return $res.VolumeId
    }
}
