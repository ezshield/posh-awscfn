
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Template  | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Template.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Parameter | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Parameter.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Mapping   | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Mapping.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Condition | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Condition.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Resource  | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Resource.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Output    | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Output.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Property  | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Property.md
& "$PSScriptRoot\Get-HelpByMarkdown.ps1" Tag       | Out-File -Encoding utf8 -FilePath $PSScriptRoot\..\..\help\Directive_Tag.md
