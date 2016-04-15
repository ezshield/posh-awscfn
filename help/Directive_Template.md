# **Template** *(New-CfnTemplate)*

## SYNOPSIS
A template describes your AWS infrastructure.

## SYNTAX
```powershell
New-CfnTemplate [-TemplateBlock] <ScriptBlock> [-Version <String>] [-Description <String>] [-Metadata <IDictionary>] [-JSON] [-Compress] [<CommonParameters>]
```

## DESCRIPTION
Templates include several major sections. The Resources section is the only section that is required:
 * Parameters
 * Mappings
 * Conditions
 * Resources
 * Outputs

Some sections in a template can be in any order. However, as you build your template, it might be helpful to use the logical ordering of the previous example, as values in one section might refer to values from a previous section.

## PARAMETERS
### -TemplateBlock &lt;ScriptBlock&gt;

```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Version &lt;String&gt;

```
Required?                    false
Position?                    named
Default value                2010-09-09
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Description &lt;String&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Metadata &lt;IDictionary&gt;

```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -JSON &lt;SwitchParameter&gt;

```
Required?                    false
Position?                    named
Default value                False
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Compress &lt;SwitchParameter&gt;

```
Required?                    false
Position?                    named
Default value                False
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
