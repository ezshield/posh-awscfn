
<#
Usage:
    Generate-CfnResources.ps1 > CfnResources.generated.ps1
#>

## Mapping of schema property types to their
## POSH cmdlet parameter type counterparts
$RES_PROP_TYPES = @{
    String    = 'string'
    Object    = 'System.Collections.IDictionary'
    Array     = 'array'
    Number    = 'int'
    Boolean   = 'bool'
    JSON      = 'object'
    Reference = 'string' # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitcondition.html
    Policy    = 'object' # JSON http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html
    DestinationCidrBlock = 'string' # docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpn-connection-route.html
}

## List of any resources to skip from auto-generation
$RES_EXCLUDE = @(
    ## We exclude this from the auto-generated resource
    ## directives because we have a manually-crafted version
    'AWS::CloudFormation::CustomResource'
)

## The CFN Schema file has some inconsistencies and errors so this is
## a way for us to manually merge in changes to the schema to correct
$RES_FIX_CHG_PROPS = @{
    "AWS::EC2::VPC" = @{
        "InstanceTenancy" = @{
            "type" = "String"
        }
    }
    "AWS::EC2::Instance" = @{
        "SsmAssociations" = @{
            "type" = "object[]"
        }
    }
}
$RES_FIX_ADD_PROPS = @{
    "AWS::EC2::Route" = @{
        "NatGatewayId" = @{
            "type"              = "String"
            "resource-ref-type" = "AWS::EC2::NetworkInterface"
            "required"          = $false
            "description"       = "The ID of a NAT gateway. For example, nat-0a12bc456789de0fg. Required: Conditional. You must provide only one of the following: a GatewayID, InstanceID, NatGatewayId or NetworkInterfaceId."
        }
    }
}

$cfnSchema = ConvertFrom-Json ([System.IO.File]::ReadAllText("$PSScriptRoot\CloudFormationV1.schema"))
$resDefs = @{}

$resNamesArray = ''
$resFunctions = ''

foreach ($resType in ($cfnSchema.'root-schema-object'.properties.Resources.'child-schemas' | gm -MemberType NoteProperty <#| select -First 1#>)) {
    $resName = $resType.Name
    if ($RES_EXCLUDE.Contains($resName)) {
        continue
    }

    $resDef = $cfnSchema.'root-schema-object'.properties.Resources.'child-schemas'.($resName)
    if (-not ($resName -match '^AWS::(.+)::(.+)$')) {
        Write-Warning "Resource [$resName] does not match expected naming convention; SKIPPING"
        continue
    }

    $funName = "Add-Cfn$($Matches[1])_$($Matches[2])Resource"
    $akaName = "Res-$($Matches[1])-$($Matches[2])"
    $resDescription  = $resDef.description
    $resDeletePolicy = $resDef.properties.DeletionPolicy.'allowed-values'
    $resMetaData     = $resDef.properties.Metadata

    $resCreationPolicy = $resDef.properties.CreationPolicy.description
    $resUpdatePolicy   = $resDef.properties.UpdatePolicy.description

    $paramsHelp = ""
    $paramsAtt = ""
    $paramsDef = ""
    $paramsAdd = ""
    if (-not $resDef.properties.Properties.properties) {
        Write-Warning "Resource type [$resName] has no parameter properties"
    }
    else {
        #region -- Properties --
        $resPropNames = ($resDef.properties.Properties.properties | gm -MemberType NoteProperty).Name

        $hasUsername = $resPropNames | ? { $_ -imatch 'username' }
        $hasPassword = $resPropNames | ? { $_ -imatch 'password' }
        if ($hasUsername -and $hasPassword) {
            Write-Warning "Resource type [$resName] includes Username [$hasUsername] & Password [$hasPassword] parameters; suppressing PSScriptAnalyzer"
            $paramsAtt += @"
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '$hasUsername')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '$hasPassword')]
"@
        }

        $resPropDefs = [ordered]@{}
        foreach ($resPropName in $resPropNames) {
            $resProp = $resDef.properties.Properties.properties.$resPropName
            $resPropDefs.$resPropName = $resProp
        }
        if ($RES_FIX_ADD_PROPS[$resName]) {
            foreach ($resPropName in $RES_FIX_ADD_PROPS[$resName].Keys) {
                Write-Warning "Adding property correction [$resPropName] for [$resName]"
                $resPropDefs.$resPropName = $RES_FIX_ADD_PROPS[$resName].$resPropName
            }
        }


        foreach ($resPropName in $resPropDefs.Keys) {
            $resProp = $resPropDefs[$resPropName]

            $resPropType    = $RES_PROP_TYPES[$resProp.type]
            if ($RES_FIX_CHG_PROPS.$resName.$resPropName.type) {
                Write-Warning "Intercepted type correction [$($RES_FIX_CHG_PROPS.$resName.$resPropName.type)] for [$($resName)][$($resPropName)][$($resPropType)]"
                $resPropType = $RES_FIX_CHG_PROPS.$resName.$resPropName.type
            }

            if (-not $resPropType) {
                Write-Warning "Unknown property type of [$($resProp.type)] for [$resName][$resPropName]; SKIPPING"
                continue
            }

            $resPropSubtype = $resProp.'array-type'
            if ($resPropSubtype) {
                $resPropSubtype = $RES_PROP_TYPES[$resProp.'array-type']
                if (-not $resPropSubType) {
                    Write-Warning "Unknown property sub-type of [$($resProp.'array-type')] for [$resName][$resPropName]; SKIPPING"
                    continue
                }
            }

            $resPropRefType = $resProp.'resource-ref-type'
            $resPropValid   = $resProp.'allowed-values'
            $resPropProps   = ($resProp | gm -MemberType NoteProperty).Name

            ## Special support for Tags starts here
            $tagProps = $null
            if ($resPropName -cmatch 'Tag') {
                $tagProps = ($resProp.properties | gm -MemberType NoteProperty).Name
                $tagExtraProps = $tagProps | ? { $_ -notmatch '(Key|Value)' }
                if ($tagExtraProps.Length -gt 0) {
                    Write-Warning "Tag Property [$resPropName] for [$resName] contains extra props [$tagProps]"
                }
            }

            if ($tagProps) {
                $paramsDef += "    [System.Collections.IDictionary]`$$resPropName, # $resPropProps `n`n"
            }
            else {
                if ($resPropValid) {
                    $paramsDef += "    [ValidateSet('" + [string]::Join("','", $resPropValid) + "')]`n"
                }
                if ($resPropType -eq 'array') {
                   #$paramsDef += "    [cfnproparr[$resPropSubtype]]`$$resPropName, #[$resPropType][$resPropSubtype] $resPropProps `n`n"
                    $paramsDef += "    [$resPropSubtype[]]`$$resPropName, #[$resPropType][$resPropSubtype] $resPropProps `n`n"
                }
                else {
                   #$paramsDef += "    [cfnpropval[$resPropType]]`$$resPropName, # $resPropProps `n`n"
                    $paramsDef += "    [$resPropType]`$$resPropName, # $resPropProps `n`n"
                }
            }

            $paramsHelp += @"
.PARAMETER $($resPropName)
$($resProp.description)

"@

            if ($tagProps) {
                $paramsAdd += @"
  if (`$PSBoundParameters.ContainsKey('$resPropName')) {
    `$tagsList = New-Object System.Collections.ArrayList
    foreach (`$tk in `$$resPropName.Keys) {
      `$t = @{ Key = `$tk }
      `$tv = `$$resPropName[`$tk]

"@
                if ($tagExtraProps -and $tagExtraProps.Length) {
                    $tagPropsNames = "'Value','" + [string]::Join("','", $tagExtraProps) + "'"
                    $paramsAdd += @"
      if (-not (`$tv -is [System.Collections.IDictionary])) {
        throw "Tag property [$resPropName] requires a dictionary of values"
      }
      foreach (`$tvp in `$tv.Keys) {
        if (`$tvp -notin ($tagPropsNames)) {
          throw "Tag property [$resPropName] must be a dictionary with keys [$tagPropsNames]"
        }
        `$t[`$tvp] = `$tv[`$tvp]
      }

"@
                }
                else {
                    $paramsAdd += @"
      `$t.Value = `$tv

"@
                }

                $paramsAdd += @"
      `$tagsList += `$t
    }
    `$rProperties.$resPropName = `$tagsList
  }

"@
            }
            else {
                $paramsAdd += @"
  if (`$PSBoundParameters.ContainsKey('$resPropName')) {
    `$rProperties.$resPropName = `$$resPropName
  }

"@
            }
        }
        #endregion -- Properties --
    }

    $paramsAdd += @'
  ## Resource Attributes

'@

    if ($resDeletePolicy) {
        $paramsDef += "    [ValidateSet('$([string]::Join(`"','`", $resDeletePolicy))')]`n"
        $paramsDef += "    [string]`$DeletionPolicy,`n"
        $paramsHelp += @"
.PARAMETER DeletionPolicy
With the DeletionPolicy attribute you can preserve or (in some cases) backup a resource when its stack is deleted. You specify a DeletionPolicy attribute for each resource that you want to control. If a resource has no DeletionPolicy attribute, AWS CloudFormation deletes the resource by default.

To keep a resource when its stack is deleted, specify Retain for that resource. You can use retain for any resource. For example, you can retain a nested stack, S3 bucket, or EC2 instance so that you can continue to use or modify those resources after you delete their stacks.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html

"@
        $paramsAdd += @'
  if ($DeletionPolicy) {
    $r.DeletionPolicy = $DeletionPolicy
  }

'@
    }
    if ($resMetaData) {
        $paramsDef += "    [hashtable]`$Metadata,`n"
        $paramsHelp += @"
.PARAMETER Metadata
The Metadata attribute enables you to associate structured data with a resource. By adding a Metadata attribute to a resource, you can add data in JSON format to the resource declaration. In addition, you can use intrinsic functions (such as GetAtt and Ref), parameters, and pseudo parameters within the Metadata attribute to add those interpreted values.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-metadata.html

"@
        $paramsAdd += @'
  if ($Metadata) {
    $r.Metadata = $Metadata
  }

'@
    }
    if ($resCreationPolicy) {
        $paramsDef += "    [hashtable]`$CreationPolicy,`n"
        $paramsHelp += @"
.PARAMETER CreationPolicy
You associate the CreationPolicy attribute with a resource to prevent its status from reaching create complete until AWS CloudFormation receives a specified number of success signals or the timeout period is exceeded. To signal a resource, you can use the cfn-signal helper script or SignalResource API. AWS CloudFormation publishes valid signals to the stack events so that you track the number of signals sent.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html

"@
        $paramsAdd += @'
  if ($CreationPolicy) {
    $r.CreationPolicy = $CreationPolicy
  }

'@
    }

    #region -- UpdatePolicy --
    if ($resUpdatePolicy) {
        $paramsDef += "    [hashtable]`$UpdatePolicy,`n"
        $paramsHelp += @"
.PARAMETER UpdatePolicy
You can use the UpdatePolicy attribute to specify how AWS CloudFormation handles updates to the AWS::AutoScaling::AutoScalingGroup resource.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html

"@
        $paramsAdd += @'
  if ($UpdatePolicy) {
    $r.UpdatePolicy = $UpdatePolicy
  }

'@
    }
    #endregion -- UpdatePolicy --

    #region -- DependsOn --
    $paramsDef += "    [array]`$DependsOn,`n"
    $paramsHelp += @"
.PARAMETER DependsOn
With the DependsOn attribute you can specify that the creation of a specific resource follows another. When you add a DependsOn attribute to a resource, that resource is created only after the creation of the resource specified in the DependsOn attribute. You can use the DependsOn attribute with any resource.
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html

"@
    $paramsAdd += @'
  if ($DependsOn) {
    $r.DependsOn = $DependsOn
  }

'@
    #endregion -- DependsOn --

    #region -- PropertiesBlock --
    $paramsDef += "    [Parameter(Position=1)]`n"
    $paramsDef += "    [scriptblock]`$PropertiesBlock`n"
    $paramsHelp += @"
.PARAMETER PropertiesBlock
Allows you to declare a block of one or more Property statements.

A Properties block allows you to side-step the rigid, type-enforced literal properties of a typed resource, and specify Property assignments that may include CloudFormation function calls or references, or computed values.

"@
    $paramsAdd += @'
  if ($PropertiesBlock) {
    & $PropertiesBlock
  }

'@
    #endregion -- PropertiesBlock --


    $resNamesArray += @"
,'$resName'

"@

    $resFunctions += @"
function $funName {
<#
.SYNOPSIS
$($resDescription)
$($paramsHelp)
.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html
.LINK
http://docs.aws.amazon.com/search/doc-search.html?searchPath=documentation&searchQuery=$([uri]::EscapeUriString($resName))
#>
$paramsAtt
  param(
    [Parameter(Mandatory,Position=0)]
    [string]`$ResourceName,

$paramsDef,

    [object]`$Condition
  )

  `$tResources = [System.Collections.IDictionary](Get-Variable -Name "tResources" -ValueOnly)
  if (-not `$tResources) {
    throw "Template Resrouces collection is not in scope"
  }

  if (`$tResources.Contains(`$ResourceName)) {
    throw "Duplicate Resource name [`$ResourceName]"
  }

  `$r = [ordered]@{ Type = "$resName" }
  `$rProperties = [ordered]@{}

  $(if ($paramsAdd) { @"
  ## Resource Properties
$paramsAdd
"@
  })

  if (`$Condition) {
    `$r.Condition = `$Condition
  }

  if (`$rProperties -and `$rProperties.Count) {
    `$r.Properties = `$rProperties
  }

  `$tResources.Add(`$ResourceName, `$r)
}
Set-Alias -Name $akaName -Value $funName


"@
}

@"
<#
WARNING:  THIS FILE IS AUTO-GENERATED! MANUAL CHANGES TO THIS
          FILE *WILL BE LOST* AFTER THE NEXT AUTO-GENERATION!

Generated By:  [$($env:USERNAME)]
Generated At:  [$([DateTime]::Now.ToString("yyyyMMdd_HHmmss"))]
Generated On:  [$($env:COMPUTERNAME)]
Generated W/:  [$([System.IO.Path]::GetFileName($PSCommandPath))]
#>

`$AWSCFN_RESOURCE_TYPES = @(
$resNamesArray
)

"@

@'
function Add-CfnResource {
<#
.SYNOPSIS
The required Resources section declare the AWS resources that you want as part of your stack, such as an Amazon EC2 instance or an Amazon S3 bucket. 

.DESCRIPTION
You must declare each resource separately; however, you can specify multiple resources of the same type.

Resources can be added to a template using one of two forms, either a generic Resource declaration or a strongly-typed Resource-specific declaration.  This cmdlet provides the generic Resource declaration support.

.PARAMETER ResourceName
The logical ID which must be alphanumeric (A-Za-z0-9) and unique within the template.

You use the logical name to reference the resource in other parts of the template. For example, if you want to map an Amazon Elastic Block Store to an Amazon EC2 instance, you reference the logical IDs to associate the block stores with the instance.

.PARAMETER Type
The resource type identifies the type of resource that you are declaring.

For example, the AWS::EC2::Instance declares an Amazon EC2 instance. For a list of all the resource types, see AWS Resource Types Reference.

.PARAMETER RawType
An alternative to the Type parameter, this allows you to specify an unrestricted and unvalidated type name.

.PARAMETER Properties
Resource properties are additional options that you can specify for a resource.

For example, for each Amazon EC2 instance, you must specify an AMI ID for that instance. You declare the AMI ID as a property of the instance.

If a resource does not require any properties to be declared, omit the properties.

Property values can be literal strings, lists of strings, Booleans, parameter references, pseudo references, or the value returned by a function. These rules apply when you combine literals, lists, references, and functions to obtain a value.

.PARAMETER PropertiesBlock
Allows you to declare a block of one or more Property statements.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html
#>
'@
@'
    [CmdletBinding(DefaultParameterSetName="Type")]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ResourceName,
        [Parameter(Mandatory,ParameterSetName="Type",Position=1)]
        [ValidateSet(
#region -- Resource Types --
'@
$resNamesArray.Replace(',', "`t`t,").Substring(3)
@'
#endregion
        )]
        [string]$Type,
        [Parameter(Mandatory,ParameterSetName="RawType",Position=1)]
        [string]$RawType,
        [System.Collections.IDictionary]$Properties,
        [object]$Condition,
        [Parameter(Position=2)]
        [scriptblock]$PropertiesBlock
    )

    $tResources = [System.Collections.IDictionary](Get-Variable -Name "tResources" -ValueOnly)
    if (-not $tResources) {
        throw "Template Resources collection is not in scope"
    }
        
    if ($tResources.Contains($ResourceName)) {
        throw "Duplicate Resource name [$ResourceName]"
    }

    if ($RawType) {
        $Type = $RawType
    }

    $r = [ordered]@{ Type = $Type }
    $rProperties = [ordered]@{}

    if ($Properties -and $Properties.Count) {
        foreach ($pk in $Properties.Keys) {
            $rProperties = $Properties[$pk]
        }
    }

    if ($Condition) {
        $r.Condition = $Condition
    }

    if ($PropertiesBlock) {
        & $PropertiesBlock
    }

    if ($rProperties -and $rProperties.Count) {
        $r.Properties = $rProperties
    }

    $tResources.Add($ResourceName, $r)
}
Set-Alias -Name Resource -Value Add-CfnResource

'@

@"
$resFunctions
"@
