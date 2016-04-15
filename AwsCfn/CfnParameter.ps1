<#
.SYNOPSIS
You can use the optional Parameters section to pass values into your template when you create a stack. 

.DESCRIPTION
With parameters, you can create templates that are customized each time you create a stack. Each parameter must contain a value when you create a stack. You can specify a default value to make the parameter optional.

You have a maximum of 60 parameters in an AWS CloudFormation template.

.PARAMETER ParameterName
For each Parameter, you must declare a logical name. The logical name must be alphanumeric and unique among all logical names within the Template. After you declare the parameter's logical name, you can specify the parameter's properties.

.PARAMETER Type
You must declare parameters as one of following types: String, Number, CommaDelimitedList, or an AWS-specific type. For String, Number, and AWS-specific parameter types, you can define constraints that AWS CloudFormation uses to validate the value of the parameter.

AWS-specific parameter types are AWS values such as Amazon EC2 key pair names and VPC IDs. AWS CloudFormation validates these parameter values against existing values in users' AWS accounts. AWS-specific parameter types are helpful in catching invalid values at the start of creating or updating a stack.

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html

.LINK
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudformation-interface.html
#>
function Add-CfnParameter {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ParameterName,
        [Parameter(Mandatory,Position=1)]
        [ValidateSet(
            "String",
            "Number",
            "List<Number>",
            "CommaDelimitedList",
            "AWS::EC2::AvailabilityZone::Name",
            "List<AWS::EC2::AvailabilityZone::Name>",
            "AWS::EC2::Instance::Id",
            "List<AWS::EC2::Instance::Id>",
            "AWS::EC2::Image::Id",
            "List<AWS::EC2::Image::Id>",
            "AWS::EC2::KeyPair::KeyName",
            "AWS::EC2::SecurityGroup::Id",
            "List<AWS::EC2::SecurityGroup::Id>",
            "AWS::EC2::SecurityGroup::GroupName",
            "List<AWS::EC2::SecurityGroup::GroupName>",
            "AWS::EC2::Subnet::Id",
            "List<AWS::EC2::Subnet::Id>",
            "AWS::EC2::Volume::Id",
            "List<AWS::EC2::Volume::Id>",
            "AWS::EC2::VPC::Id",
            "List<AWS::EC2::VPC::Id>",
            "AWS::Route53::HostedZone::Id",
            "List<AWS::Route53::HostedZone::Id>")]
        [string]$Type,

        [Parameter(Position=2)]
        [ValidateLength(1,4000)]
        [string]$Description,

        [ValidateLength(1,4000)]
        [Parameter(Position=3)]
        [string]$ConstraintDescription,

        [string]$ConsoleGroup,
        [string]$ConsoleLabel,

        ## Needs to be an object to support
        ## rich types like objects and arrays
        [object]$Default,
        [switch]$NoEcho,
        [array]$AllowedValues,
        [string]$AllowedPattern,
        [int]$MinLength,
        [int]$MaxLength,
        [int]$MinValue,
        [int]$MaxValue
    )

    $tParameters = [System.Collections.IDictionary](Get-Variable -Name "tParameters" -ValueOnly)
    if (-not $tParameters) {
        throw "Template Parameters collection is not in scope"
    }

    $tMetadata = [System.Collections.IDictionary](Get-Variable -Name "tMetadata" -ValueOnly)
    if (-not $tMetadata) {
        throw "Template Metadata collection is not in scope"
    }

    if ($tParameters.Contains($ParameterName)) {
        throw "Duplicate Parameter name [$ParameterName]"
    }

    $p = [ordered]@{ Type = $Type }
    $tParameters.Add($ParameterName, $p)

    if ($Description          ) { $p.Description           = $Description           }
    if ($ConstraintDescription) { $p.ConstraintDescription = $ConstraintDescription }
    if ($Default              ) { $p.Default               = $Default               }
    if ($NoEcho               ) { $p.NoEcho                = [string]$NoEcho        }
    if ($AllowedValues        ) { $p.AllowedValues         = $AllowedValues         }
    if ($AllowedPattern       ) { $p.AllowedPattern        = $AllowedPattern        }
    if ($MinLength            ) { $p.MinLength             = [string]$MinLength     }
    if ($MaxLength            ) { $p.MaxLength             = [string]$MaxLength     }
    if ($MinValue             ) { $p.MinValue              = [string]$MinValue      }
    if ($MaxValue             ) { $p.MaxValue              = [string]$MaxValue      }

    if ($ConsoleGroup -or $ConsoleLabel) {
        ## From:  http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudformation-interface.html
        $interface = $tMetadata["AWS::CloudFormation::Interface"]
        if (-not $interface) {
            $interface = [ordered]@{}
            $tMetadata["AWS::CloudFormation::Interface"] = $interface
        }

        if ($ConsoleGroup) {
            $interfaceGroups = $interface["ParameterGroups"]
            if (-not $interfaceGroups) {
                $interfaceGroups = @()
            }
            $paramGroup = $interfaceGroups | ? { $_.Label -eq $ConsoleGroup }
            if (-not $paramGroup) {
                $paramGroup = [ordered]@{ Label = $ConsoleGroup; Parameters = @() }
                $interfaceGroups += $paramGroup
            }
            $paramGroup.Parameters += $ParameterName
            $interface["ParameterGroups"] = $interfaceGroups
        }

        if ($ConsoleLabel) {
            $interfaceLabels = $interface["ParameterLabels"]
            if (-not $interfaceLabels) {
                $interfaceLabels = [ordered]@{}
            }
            $interfaceLabels[$ParameterName] = @{ default = $ConsoleLabel }
            $interface["ParameterLabels"] = $interfaceLabels
        }
    }
}
Set-Alias -Name Parameter -Value Add-CfnParameter
