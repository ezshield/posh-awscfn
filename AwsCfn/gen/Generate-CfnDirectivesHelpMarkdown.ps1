
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Template   > $PSScriptRoot\..\..\help\Directive_Template.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Parameter  > $PSScriptRoot\..\..\help\Directive_Parameter.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Mapping    > $PSScriptRoot\..\..\help\Directive_Mapping.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Condition  > $PSScriptRoot\..\..\help\Directive_Condition.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Resource   > $PSScriptRoot\..\..\help\Directive_Resource.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Output     > $PSScriptRoot\..\..\help\Directive_Output.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Property   > $PSScriptRoot\..\..\help\Directive_Property.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Tag        > $PSScriptRoot\..\..\help\Directive_Tag.md

