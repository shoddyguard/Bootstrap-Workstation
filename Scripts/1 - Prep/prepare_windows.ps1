<#
.SYNOPSIS
    This script will prepare a Windows machine for use with this project.
.DESCRIPTION
    Installs our dependencies, and sets up the environment for the project.
#>
$ErrorActionPreference = 'Stop'
try
{
    $ChocoCheck = Get-Command 'choco'
    $PWSHCheck = Get-Command 'pwsh'
}
catch
{
    # Do nothing
}
if (!$ChocoCheck)
{
    Write-Host 'Installing Chocolatey...'
    try
    {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        # Reload the path
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User') 
    }
    catch
    {
        throw "Failed to install Chocolatey.$($_.Exception.Message)"
    }
}
if (!$PWSHCheck)
{
    Write-Host 'Installing PowerShell Core...'
    choco install -y pwsh
    if ($LASTEXITCODE -ne 0)
    {
        throw "Failed to install PowerShell Core.`nAn unexpected exit code was returned:$($LASTEXITCODE)"
    }
    # Reload the path
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User') 
}
Write-Host "`nMachine is now ready to be bootstrapped. 👢" -ForegroundColor Green