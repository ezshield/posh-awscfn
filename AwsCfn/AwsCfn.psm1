
##
## This file reserved for any future general code to be run at time of module load
##

## Playing around with the idea of using POSH Type Accelerators to further enforce specific types

#$TYPEXLR8 = [System.Management.Automation.TypeAccelerators]
#if (-not [PSObject].Assembly.GetType($TYPEXLR8)::Get['accelerators']) {
#    [PSObject].Assembly.GetType($TYPEXLR8)::Add([accelerators], [PSObject].Assembly.GetType($TYPEXLR8))
#}
#
#if (-not [accelerators]::Get['cfnprop']) {
#    [accelerators]::Add('cfnprop', [POSH.AwsCfn.CfnPropertyValue])
#}
#if (-not [accelerators]::Get['cfnpropfn']) {
#    [accelerators]::Add('cfnpropfn', [POSH.AwsCfn.CfnPropertyFnValue])
#}
#if (-not [accelerators]::Get['cfnpropval']) {
#    [accelerators]::Add('cfnpropval', [POSH.AwsCfn.CfnPropertyTypedValue[object]].GetGenericTypeDefinition())
#}
#if (-not [accelerators]::Get['cfnproparr']) {
#    [accelerators]::Add('cfnproparr', [POSH.AwsCfn.CfnPropertyTypedArrayValue[object]].GetGenericTypeDefinition())
#}
