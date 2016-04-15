
## To Undefine these functions during dev/test:
##    Remove-Item Function:\Set-AwsCfnStack
##    Remove-Item Function:\Add-CfnStackDefaults
##    Remove-Item Function:\Use-CfnTemplate

Set-Alias -Name Apply-CfnStack -Value Set-AwsCfnStack
function Set-AwsCfnStack {
<#
.SYNOPSIS
Either creates or updates a CloudFormation Stack.

.PARAMETER StackName
The name of the CFN Stack to Create or Update.

.PARAMETER TemplateBody
The JSON content of a CFN Stack Template.
If the size of this value exceeds 51,200 bytes then it must be applied using an S3 URL which is specified using the TempUrl* parameters.

.PARAMETER DeleteRollback
If specified, then when attempting to update the Security Groups definition stack, if the stack is currently in any "ROLLBACK_*" state, the stack will first be deleted, and then created from scratch.
If this flag is not specified, and the stack is in any ROLLBACK_* state, then the stack update request will fail because it was never created successfully to begin with.

.PARAMETER ChangeSetFmtStr
A string format expression that is used to derive a unique ChangeSet name.  The following format arguments are made available:
    0 - Stack Name
    1 - Username
    2 - Timestamp with seconds precision

.PARAMETER TempUrlFmtStr
A string format expression that is used to derive a unique Temporary URL S3 Key.  The following format arguments are made available:
    0 - Stack Name
    1 - Username
    2 - Timestamp with seconds precision

#>
    [CmdletBinding(DefaultParameterSetName="TemplateBody")]
    param (
        [Parameter(Mandatory=$true,ParameterSetName="TemplateBody")]
        [string]$TemplateBody,
        [Parameter(Mandatory=$true,ParameterSetName="TemplateUrl")]
        [string]$TemplateUrl,

        [Parameter(Mandatory=$true)]
        [string]$StackName,
        [switch]$ChangeSet,
        [string]$ChangeSetFmtStr="CFNCHG-{1}-{2}",
        [string]$ChangeSetDesc,

        [string]$TempUrlBucket,
        [string]$TempUrlFmtStr="CFN-{0}-{1}-{2}",
        [switch]$ForceTempUrl,
        [switch]$KeepTempUrl,

        [string]$StackPolicy,

        [Parameter(Mandatory=$false)]
        [switch]$DeleteRollback,

        [Parameter(Mandatory=$false)]
        [switch]$WhatIf,

        ## Base params for all AWS calls
        [Parameter(Mandatory=$false)]
        [string]$ProfileName,
        [Parameter(Mandatory=$false)]
        [string]$Region
    )

    ## Base parameters for all AWS commands
    $awsBaseParams = @{
        ProfileName = $ProfileName
        Region      = $Region
    }

    $whatIfParams = @{}
    if ($WhatIf) {
        Write-Warning 'Running "WhatIf" scenario'
        $whatIfParams.WhatIf = $true
    }

    if ($TemplateUrl) {
        $ForceTempUrl = $true
        $KeepTempUrl = $true
    }
    elseif ($TemplateBody.Length -gt 51200) {
        Write-Verbose "Template Body exceeds inline limit; forcing temporary S3 URL"
        $ForceTempUrl = $true
    }

    $tempUrlFmtStr_0 = $StackName
    $tempUrlFmtStr_1 = $env:USERNAME
    $tempUrlFmtStr_2 = [datetime]::Now.ToString('yyyyMMddHHmmss')

    $unqName = "$()-$([datetime]::Now.ToString('yyyyMMddHHmmss'))"

    try {
        if ($ForceTempUrl) {
            Write-Verbose "Using temporary S3 URL"

            if (-not $TempUrlBucket) {
                throw "Template Body exceeds inline limit and no Temporary URL Bucket specified"
            }

            $tempKey = $TempUrlFmtStr -f @(
                    $tempUrlFmtStr_0
                    $tempUrlFmtStr_1
                    $tempUrlFmtStr_2
                )
            $tempUrl = "https://s3.amazonaws.com/$($TempUrlBucket)/$($tempKey)"
            Write-Verbose "Sending template through temporary S3 URL [$($tempUrl)]"

            $writeParams = @{
                BucketName               = $TempUrlBucket
                Key                      = $tempKey
                Content                  = $TemplateBody
                ServerSideEncryption     = 'AES256'
                ReducedRedundancyStorage = $true
            }
            Write-S3Object @writeParams @awsBaseParams

            $TemplateUrl = $tempUrl
        }

        ## First test the template to make sure it's valid and passes the basic checks
        $testResult = Test-CFNTemplate -TemplateBody $TemplateBody -ErrorAction Stop @awsBaseParams
        Write-Verbose "CFN Template Test Passed"

        ## Get existing stack so we know if we need to create or update
        $cfnStack = $null
        try {
            $cfnStack = Get-CFNStack -StackName $StackName -ErrorAction Continue @awsBaseParams
        }
        catch { }

        if ($ChangeSet -and (-not $cfnStack)) {
            Write-Warning "Changeset requested but no existing stack found; SKIPPING Changeset"
        }

        ## Valid Stack Statuses:
        ##    CREATE_COMPLETE
        ##    CREATE_IN_PROGRESS
        ##    CREATE_FAILED
        ##    DELETE_COMPLETE
        ##    DELETE_FAILED
        ##    DELETE_IN_PROGRESS
        ##    ROLLBACK_COMPLETE
        ##    ROLLBACK_FAILED
        ##    ROLLBACK_IN_PROGRESS
        ##    UPDATE_COMPLETE
        ##    UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
        ##    UPDATE_IN_PROGRESS
        ##    UPDATE_ROLLBACK_COMPLETE
        ##    UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
        ##    UPDATE_ROLLBACK_FAILED
        ##    UPDATE_ROLLBACK_IN_PROGRESS

        ## First check for existing stack in a ROLLBACK_* state;
        ## we can't update this, since it has to be removed first
        if ($cfnStack -and ($cfnStack.StackStatus -like "ROLLBACK_*")) {
            Write-Warning "Existing stack [$($cfnStack.StackName)] is in ROLLBACK state [($($cfnStack.StackStatus))]"
            if ($DeleteRollback) {
                Write-Verbose "Deleting ROLLBACK stack [$($cfnStack.StackName)]"
                Remove-CFNStack -StackName $cfnStack.StackName @whatIfParams @awsBaseParams

                ## Re-retrieve the stack to make sure it's gone
                try {
                    $cfnStack = Get-CFNStack -StackName $StackName -ErrorAction Continue @awsBaseParams
                }
                catch {
                    $cfnStack = $null
                }
                if ($cfnStack) {
                    $cfnStackStatusDeleting = [Amazon.CloudFormation.StackStatus]::DELETE_IN_PROGRESS
                    $cfnStackStatusDeleted = [Amazon.CloudFormation.StackStatus]::DELETE_COMPLETE
                    $waitCount = 10
                    while ($cfnStack -and ($cfnStack.StackStatus -eq $cfnStackStatusDeleting)) {
                        if (-not $waitCount--) {
                            break
                        }
                        sleep -s 10
                        try {
                            $cfnStack = Get-CFNStack -StackName $StackName -ErrorAction Continue @awsBaseParams
                        }
                        catch {
                            $cfnStack = $null
                        }
                    }

                    if ($cfnStack -and ($cfnStack.StackStatus -ne $cfnStackStatusDeleted)) {
                        Write-Warning "Failed to delete existing stack [$cfnStackStatus]; ABORTING"
                        return
                    }
                }
            }
            else {
                Write-Warning "ABORTING!  Specify -DeleteRollback to delete existing stack in Rollback state"
                return
            }
        }

        ## Assemble all the parameters we'll use in the subsequent calls
        $cfnStackParams = @{
            StackName    = $StackName
        }
        if ($TemplateUrl) {
            $cfnStackParams.TemplateURL = $TemplateUrl
        }
        else {
            $cfnStackParams.TemplateBody = $TemplateBody
        }

        ## Next check for existing stack
        if ($cfnStack) {
            if ($ChangeSet) {
                $changeSetFmtStr_0 = $StackName
                $changeSetFmtStr_1 = $env:USERNAME
                $changeSetFmtStr_2 = [datetime]::Now.ToString('yyyyMMddHHmmss')
                $changeSetName = $ChangeSetFmtStr -f @(
                        $changeSetFmtStr_0
                        $changeSetFmtStr_1
                        $changeSetFmtStr_2
                    )

                $newCsParams = @{
                    ChangeSetName = $changeSetName
                }
                if ($ChangeSetDesc) { $newCsParams.Description = $ChangeSetDesc }

                Write-Verbose "Creating CHANGESET [$($newCsParams.ChangeSetName)] for stack [$($cfnStack.StackName)]"
                if (-not $WhatIf) {
                    New-CFNChangeSet @cfnStackParams @newCsParams @awsBaseParams
                    Write-Warning "Don't forget to REVIEW and EXECUTE Changeset [$($newCsParams.ChangeSetName)]"
                }
            }
            else {
                ## If it's in a *_COMPLETE state, do an update of an existing stack
                if ($cfnStack.StackStatus -like "*_COMPLETE") {
                    Write-Verbose "Updating EXISTING stack [$($cfnStack.StackName)][$($cfnStack.StackId)]"
                    if (-not $WhatIf) {
                        Update-CFNStack @cfnStackParams @awsBaseParams
                    }
                }
                ## Otherwise we don't know what to do with an
                ## existing stack in an unsupported state
                else {
                    Write-Warning "Existing stack [$($cfnStack.StackName)] is in" +
                            " an unsupported intermediate state [$($cfnStack.StackStatus)]"
                    throw "Existing stack in unsupported intermediate state"
                }
            }
        }
        ## Finally if stack is missing we try to create it
        else {
            Write-Verbose "Creating NEW stack [$($StackName)]"
            if (-not $WhatIf) {
                New-CFNStack @cfnStackParams -OnFailure ROLLBACK @awsBaseParams
            }
        }
    }
    finally {
        ## Clean up after ourselves
        if ($TemplateUrl) {
            if (-not $tempKey) {
                Write-Verbose "Leaving Template URL alone"
            }
            elseif ($KeepTempUrl) {
                Write-Verbose "Keep flag set; leaving Temporary URL alone"
            }
            else {
                Write-Verbose "Removing Temporary URL"
                $removeParams = @{
                    BucketName               = $TempUrlBucket
                    Key                      = $tempKey
                    Force                    = $true
                }
                Remove-S3Object @removeParams @awsBaseParams | Out-Null
            }
        }
    }
}

Set-Alias StackDefaults Add-CfnStackDefaults
function Add-CfnStackDefaults {
<#
.SYNOPSIS
Directive that allows you to associate default settings for managing a CFN Stack based on enclosing Template.
.DESCRIPTION
This cmdlet implements a Template directive which can be specified inside of a Template definition that allows you to associate several default settings used to control creating or updating a CFN Stack based on the enclosing Template.
This directive is meant to be used in concert with the Use-CfnTemplate cmdlet which knows how to combine the settings of this directive in combination with the defaults values derived from a Template.
#>
    param(
        [string]$ProfileName,
        [string]$Region,
        [string]$StackName,
        [string]$TempUrlBucket,
        [string]$TempUrlFmtStr
    )

    ## This directive uses the "Template Extensions" feature to
    ## collect policy statements and then process them and attach
    ## them as as a Stack Policy definition to the Template root

    $tExtData = Get-CfnTemplateExt -ExtData
    $tExtPost = Get-CfnTemplateExt -ExtPost
    if (-not $tExtData -or -not $tExtPost) {
        throw "Template Extensions cannot be accessed"
    }
    if ($tExtData.StackDefaults -ne $null) {
        throw "Stack Defaults can only be defined once"
    }
    $tExtData.StackDefaults = [ordered]@{
        ProfileName   = $ProfileName
        Region        = $Region
        StackName     = $StackName
        TempUrlBucket = $TempUrlBucket
        TempUrlFmtStr = $TempUrlFmtStr
    }
    $tExtPost.StackDefaults = {
            ## This is the scriptblock that will post-process
            ## the statements after the template has been defined
            param($t, $tExtData)
            $stackDefaults = $tExtData.StackDefaults
            if (-not $stackDefaults) {
                throw "Stack Defaults are expected but missing"
            }
            $t.StackDefaults = $stackDefaults
        }
}

function Use-CfnTemplate {
<#
.SYNOPSIS
Convenience tool to evaluate and apply a Template Script as a CFN Stack.
.DESCRIPTION
This cmdlet encompasses many of the common usage scenarios for evaluating and applying CFN Template Scripts including resolving sensible defaults.

It operates in one of two primary modes, 'Print' where a Template Script is evaluated and the JSON template is rendered, or 'Apply' where the template is applied as a Stack definition, either a new one, or an update to an existing one.

Internally, 'Apply' mode is implemented by invoking the Apply-CfnTemplate.  For 'Apply' mode, this cmdlet supports a limited set of direct options for controling the behavior  For more complete and elaborate control, pass the output of Print mode JSON to the Apply-CfnTemplate cmdlet directly.

.PARAMETER Path
Either the path to a Template Script (which must end in the extension .cfn.ps1) or a path containing one or more Tempate Scripts.  In the latter case the exact Template must be selected with the Name parameter.
.PARAMETER Name
If the Path parameter is unspecified, or does not specify a single, exact Tempate Script, this parameter is use to select a single Template from a list of eligible scripts from the resolved path.  This select is the name of the Template Script file, without any leading path segments, and without the mandatory script extension .cfn.ps1.
.PARAMETER JSON
In 'Print' mode, this specifies to render the Template Body as a JSON string.
.PARAMETER Compress
In 'Print' mode, augments the JSON parameter to render the Tempate Body as a compressed JSON string.
.PARAMETER ApplyStack
Enables 'Apply' mode where the resolved Template Script will be applied as  CFN Stack.
.PARAMETER StackName
In 'Apply' mode, allows you to explicitly specify the name of the Stack to be applied.  If omitted, the Stack name is resolved using either the Stack Defaults associated with the Tempate, or the Template Script filename.
.PARAMETER SkipChangeSet
In 'Apply' mode, this initiates the update of an existing Stack without the use of a ChangeSet.  By default, this cmdlet will apply all Stack updates as a ChangeSet that must then be executed as a next step.  However, with this switch, any Stack changes will be applied directly and initiated immediately to the Stack.
.PARAMETER DeleteRollback
If specified, then when attempting to update the Security Groups definition stack, if the stack is currently in any "ROLLBACK_*" state, the stack will first be deleted, and then created from scratch.
If this flag is not specified, and the stack is in any ROLLBACK_* state, then the stack update request will fail because it was never created successfully to begin with.

.LINK
Add-CfnStackDefaults
.LINK
Apply-CfnTemplate
#>
    [CmdletBinding(DefaultParameterSetName="Print")]
    param(
        [string]$Path,

        [Parameter(ParameterSetName="Print")]
        [switch]$JSON,
        [Parameter(ParameterSetName="Print")]
        [switch]$Compress,

        [Parameter(Mandatory,ParameterSetName="Apply")]
        [switch]$ApplyStack,
        [Parameter(ParameterSetName="Apply")]
        [string]$StackName,
        [Parameter(ParameterSetName="Apply")]
        [switch]$SkipChangeSet,
        [Parameter(ParameterSetName="Apply")]
        [switch]$DeleteRollback,

        [string]$ProfileName,
        [string]$Region
    )

    dynamicparam {
        ## Based on:
        ##    https://blogs.technet.microsoft.com/pstips/2014/06/09/dynamic-validateset-in-a-dynamic-parameter/

        ## First get a list of all eligible template
        ## scripts in the immediate path specified
        $root = $Path
        if (-not $root) { $root = $PWD }
        $root = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PWD, $root))
        if ([System.IO.Directory]::Exists($root)) {
            $files = Get-ChildItem -Path $root -Filter '*.cfn.ps1'
        }

        ## If we find any, then we'll dynamically add a TemplateName parameter
        if ($files -and $files.Length) {
            # Create the dictionary 
            $runtimeParams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            ## The 'Template' param

            # Set the dynamic parameters' name
            $paramName = 'Name'
            
            # Create the collection of attributes
            $attrs = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $paramAttr = New-Object System.Management.Automation.ParameterAttribute
            $paramAttr.Mandatory = $false
            $paramAttr.Position = 1

            # Add the attributes to the attributes collection
            $attrs.Add($paramAttr)

            # Generate and set the ValidateSet 
            $arrSet = $files | Select-Object -ExpandProperty Name | % { $_ -replace '\.cfn\.ps1','' }
            $validateSetAttr = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $attrs.Add($validateSetAttr)

            # Create and return the dynamic parameter
            $runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter($paramName, [string], $attrs)
            $runtimeParams.Add($paramName, $runtimeParam)

            return $runtimeParams
        }
        else {
            return $null
        }
    }

    begin {
        # Bind the parameter to a friendly variable
        $templPath = $PsBoundParameters['Path']
        $templName = $PsBoundParameters['Name']

        $tPath = $root
        $tName = $templName

        if ($tName) {
            $tPath = [System.IO.Path]::Combine($tPath, $tName)
        }
        if ($tPath -inotlike '*.cfn.ps1') {
            $tTemp = $tPath + '.cfn.ps1'
            if ([System.IO.File]::Exists($tTemp)) {
                $tPath = $tTemp
            }
        }

        if (-not [System.IO.File]::Exists($tPath)) {
            Write-Warning "Template Script file [$tPath] could not be found"
            #throw "Template Script file not found"
        }
    }

    process {
        Write-Debug "Effective root = $root"
        Write-Debug "Resolved tName = $tName"
        Write-Debug "Resolved tPath = $tPath"

        ## Assume stopping on the first error encountered but
        ## restore to former preference after we're done
        $formerEAP = $ErrorActionPreference
        $ErrorActionPreference = "stop"

        try {
            ## Evaluate Template Script
            $t = & $tPath

            if ('CfnTemplate' -ne $t.'$type') {
                throw "Evaluated Template Script does not produce expected object type"
            }
            if (-not $t.TemplateBody) {
                throw "Evaluated Template Script does not conform to expected structure"
            }
            
            $convertParams = @{ Compress = $Compress }
            $tBodyJson = $t.TemplateBody | ConvertTo-Json -Depth 100 @convertParams

            if ($ApplyStack) {
                ## Extract optional Stack Defaults or assign an empty hash
                $stackDefaults = $t.StackDefaults
                if (-not $stackDefaults) { $stackDefaults = @{} }

                ## Resolve base authn & region parameters for all AWS commands
                $awsBaseParams = @{
                    ProfileName = $ProfileName
                    Region = $Region
                }
                if (-not $awsBaseParams.ProfileName) { $awsBaseParams.ProfileName = $stackDefaults.ProfileName }
                if (-not $awsBaseParams.Region     ) { $awsBaseParams.Region      = $stackDefaults.Region      }

                ## Derive Stack Name
                if (-not $StackName) {
                    $StackName = $stackDefaults.StackName
                }
                if (-not $StackName) {
                    $StackName = [System.IO.Path]::GetFileName($tPath) -replace '.cfn.ps1',''
                }
                if (-not $StackName) {
                    throw "Stack Name could not be resolved"
                }

                ## Various "Apply" settings that may be specified
                $applyParams = @{
                    TemplateBody   = $tBodyJson
                    StackName      = $StackName
                    ChangeSet      = (-not $SkipChangeSet)
                    DeleteRollback = $DeleteRollback.IsPresent
                }
                if ($stackDefaults.TempUrlBucket) { $applyParams.TempUrlBucket = $stackDefaults.TempUrlBucket }
                if ($stackDefaults.TempUrlFmtStr) { $applyParams.TempUrlFmtStr = $stackDefaults.TempUrlFmtStr }


                ## TODO:  Incorporate StackPolicy if it's specified

                Apply-CfnStack -Verbose @applyParams @awsBaseParams
            }
            else {
                if ($JSON) {
                    $tBodyJson
                }
                else {
                    $t
                }
            }
        }
        finally {
            $ErrorActionPreference = $formerEAP
        }
    }
}
