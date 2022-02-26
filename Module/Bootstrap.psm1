#Requires -Version 7.0.0
Join-Path $PSScriptRoot -ChildPath 'Private' |
    Resolve-Path |
        Get-ChildItem -Filter *.ps1 -Recurse |
            ForEach-Object {
                . $_.FullName
            }

Join-Path $PSScriptRoot -ChildPath 'Public' |
    Resolve-Path |
        Get-ChildItem -Filter *.ps1 -Recurse |
            ForEach-Object {
                . $_.FullName
                Export-ModuleMember -Function $_.BaseName
            }

Export-ModuleMember -Alias *