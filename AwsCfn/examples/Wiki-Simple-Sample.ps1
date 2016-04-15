#ipmo -Force AwsCfn

Template -Description "Sample CloudFormation Template" -JSON -Compress {

  Parameter DBName String -Default "MyDatabase" `
    -MinLength 1 -MaxLength 64 -AllowedPattern "[a-zA-Z][a-zA-Z0-9]*" `
    -Description "The database name" `
    -ConstraintDescription "must begin with a letter and contain only alphanumeric characters."

  Parameter DBPassword String -NoEcho `
    -MinLength 1 -MaxLength 41 -AllowedPattern "[a-zA-Z0-9]+" `
    -Description "The database admin account password" `
    -ConstraintDescription "must contain only alphanumeric characters."

  Condition "Is-EC2-VPC" (Fn-Or @(
    (Fn-Equals (Pseudo Region) "eu-central-1")
    (Fn-Equals (Pseudo Region) "cn-north-1")
  ))

  ## Strongly-typed Resource definition
  Res-RDS-DBInstance MasterDB -DeletionPolicy Snapshot `
    -Engine MySQL -DBName MyDB -AllocatedStorage 5 `
    -DBInstanceClass db.m1.large -MasterUsername dbuser {
      Property MasterUserPassword (Fn-Ref DBPassword)
    }

  Output MasterJDBCConnectionString `
    -Description "JDBC connection string for the master database" `
    -Value (Fn-Join "" @(
      "jdbc:mysql://"
      (Fn-GetAtt MasterDB "Endpoint.Address")
      ":"
      (Fn-GetAtt MasterDB "Endpoint.Port")
      "/"
      (Fn-Ref DBName)
  ))

} | & "$PSScriptRoot\..\tools\Format-Json.ps1"
