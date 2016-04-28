<img src="https://cdn.rawgit.com/ezshield/posh-awscfn/master/art/logo.svg" width="96">
# posh-awscfn

---
[CloudFormation](http://aws.amazon.com/cloudformation/) is a facility in Amazon Web Services (AWS) that allows you to describe the architecture and configuration of resources on the AWS platform.  This is done using CloudFormation (CFN) Templates which declare the resources and their interdependencies in a JSON document.

This PowerShell module provides a set of cmdlets and supporting tools that allow you to describe and generate CFN Templates using the semantics and features of the PowerShell scripting language.

One of the most useful set of tools in this module allows you to write CloudFormation templates in a domain-specific vocabulary (DSV) which provides intellisense and strong-typing when describing your template definition.  Here's a quick example:

```powershell
Template -Description "Sample CloudFormation Template" {

  ## Optional template parameter
  Parameter DBPassword String -NoEcho `
    -MinLength 1 -MaxLength 41 -AllowedPattern "[a-zA-Z0-9]+" `
    -Description "The database admin account password" `
    -ConstraintDescription "must contain only alphanumeric characters."

  ## Strongly-typed Resource definition
  Res-RDS-DBInstance MasterDB -DeletionPolicy Snapshot `
    -Engine MySQL -DBName MyDB -AllocatedStorage 5 `
    -DBInstanceClass db.m1.large -MasterUsername dbuser {
      Property MasterUserPassword (Fn-Ref DBPassword)
    }
}
```

And here is the CloudFormation JSON Template it generates:

```json
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Sample CloudFormation Template",
  "Parameters": {
    "DBPassword": {
      "Type": "String",
      "Description": "The database admin account password",
      "ConstraintDescription": "must contain only alphanumeric characters.",
      "NoEcho": "True",
      "AllowedPattern": "[a-zA-Z0-9]+",
      "MinLength": "1",
      "MaxLength": "41"
    }
  },
  "Resources": {
    "MasterDB": {
      "Type": "AWS::RDS::DBInstance",
      "DeletionPolicy": "Snapshot",
      "Properties": {
        "AllocatedStorage": "5",
        "DBInstanceClass": "db.m1.large",
        "DBName": "MyDB",
        "Engine": "MySQL",
        "MasterUsername": "dbuser",
        "MasterUserPassword": {
          "Ref": "DBPassword"
        }
      }
    }
  }
}
```

You can find another sample [here](https://github.com/ezshield/posh-awscfn/wiki/Cmdlet-Conventions#sample-usage).

## Getting Started

Check out the [Getting Started wiki](https://github.com/ezshield/posh-awscfn/wiki/Getting-Started) page to get started.
