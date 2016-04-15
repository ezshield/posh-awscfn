param([string]$Path)

[regex]::Replace(
    [System.IO.File]::ReadAllText($Path),
    '\r?\n?[\t ]*<#\(ORIG\)[^>]+#>', '', 'multiline')
