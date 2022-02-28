<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param
(
    # This token will be used to add SSH/GPG keys to your GitHub account. (must have the appropriate permissions)
    [Parameter(Mandatory = $false)]
    [string]
    $GitHubToken,

    # Any additional modules from PSGallery that you want to install
    [Parameter(Mandatory = $false)]
    [array]
    $PSGalleryModuleListPath,

    # Path to a Chocolatey package file that you want to install
    [Parameter(Mandatory = $false)]
    [string]
    $ChocolateyPackageListPath,

    # Path to a CSV file containing a list of SSH keys to create
    [Parameter(Mandatory = $false)]
    [string]
    $SSHKeyListPath,

    # Path to a CSV file containing a list of VCS repositories to clone
    [Parameter(Mandatory = $false)]
    [string]
    $VCSRepoListPath,

    # Whether to generate a GitHub SSH key for the current user
    [Parameter(Mandatory = $false)]
    [bool]
    $GenerateGitHubSSHKey = $true,

    # Whether to generate a GitHub GPG key for the current user
    [Parameter(Mandatory = $false)]
    [bool]
    $GenerateGitHubGPGKey = $true,

    # The git username to use for the current user
    [Parameter(Mandatory = $false)]
    [string]
    $GitUsername,

    # The git email to use for the current user
    [Parameter(Mandatory = $false)]
    [string]
    $GitEmail,

    # If set will configure global git settings #TODO: Implement this
    [Parameter(Mandatory = $false)]
    [bool]
    $SetGlobalGitConfig = $true,

    # If set will force overwrite of existing files
    [Parameter(Mandatory = $false)]
    [switch]
    $Force
)
$ErrorActionPreference = 'Stop'
$RequiredPackages = @()
$DateStr = Get-Date -Format 'yyMMddhhmm'
Write-Host 'Beginning bootstrap process...'
# First import our module
Write-Host 'Importing the module...'
try
{
    Import-Module (Join-Path $PSScriptRoot '..\..\Module\Bootstrap.psm1') -Force
}
catch
{
    throw "Failed to import Bootstrap module.`n$($_.Exception.Message)"
}
if ($GenerateGitHubSSHKey -or $GenerateGitHubGPGKey -or $VCSRepoListPath)
{
    Write-Debug 'Will install git'
    $RequiredPackages += [pscustomobject]@{
        name    = 'git'
        version = 'any'
    }
}
if ($GenerateGitHubGPGKey)
{
    if (!$GitUsername -or !$GitEmail)
    {
        throw 'GitHub GPG key generation requires a username and email address.'
    }
    Write-Debug 'Will install gpg4win'
    $RequiredPackages += [pscustomobject]@{
        name    = 'gpg4win'
        version = 'any'
    }
}
# Install Chocolatey packages
if ($ChocolateyPackageListPath)
{
    Write-Host 'Importing Chocolatey package list...'
    try
    {
        $ChocoPackages = Import-Csv -Path $ChocolateyPackageListPath
        $RequiredPackages += $ChocoPackages
    }
    catch
    {
        throw "Failed to import Chocolatey package list file.`n$($_.Exception.Message)"
    }
}
if ($RequiredPackages)
{
    Write-Host 'Installing\checking Chocolatey packages, this may take some time...' -ForegroundColor Yellow
    try
    {
        $RequiredPackages | Install-ChocolateyPackage -ErrorAction 'Stop' # By default this cmdlet doesn't stop on errors, but we actually want to in this case.
    }
    catch
    {
        throw "Failed to install Chocolatey packages.`n$($_.Exception.Message)"
    }
    Write-Host 'Successfully installed Chocolatey packages.' -ForegroundColor Green
}
if ($PSGalleryModuleListPath)
{
    Write-Host 'Installing PowerShell Gallery modules...'
    try
    {
        $PSGalleryModules = Import-Csv -Path $PSGalleryModuleListPath
        foreach ($PSGalleryModule in $PSGalleryModules)
        {
            $ModuleCheck = Get-Module $PSGalleryModule.ModuleName -ListAvailable
            if ((!$ModuleCheck) -or ($Force))
            {
                Write-Debug "Installing $PSGalleryModule"
                $InstallParams = @{
                    Name = $PSGalleryModule.ModuleName
                    Force = $true
                }
                if ($PSGalleryModule.ModuleVersion)
                {
                    $InstallParams.Version = $PSGalleryModule.ModuleVersion
                }
                Install-Module @InstallParams
            }
        }
    }
    catch
    {
        throw "Failed to install PowerShell Gallery modules.`n$($_.Exception.Message)"
    }
    Write-Host 'Successfully installed PowerShell Gallery modules.' -ForegroundColor Green
}
if ($GenerateGitHubSSHKey -or $SSHKeyListPath)
{
    try
    {
        Install-OpenSSH
    }
    catch
    {
        throw $_.Exception.Message
    }
}
if ($GenerateGitHubSSHKey)
{
    try
    {
        New-GitHubSSHKey -GitHubToken $GitHubToken -Comment "$env:COMPUTERNAME -> GitHub $DateStr" -Force:($PSBoundParameters['Force'] -eq $true)
    }
    catch
    {
        throw "Failed to generate GitHub SSH key.`n$($_.Exception.Message)"
    }

}
if ($GenerateGitHubGPGKey)
{
    try
    {
        $GPGKey = New-GitHubGPGKey -GitHubToken $GitHubToken -Username $GitUsername -Email $GitEmail -Comment $env:COMPUTERNAME -Force:($PSBoundParameters['Force'] -eq $true)
    }
    catch
    {
        throw "Failed to generate GitHub GPG key.`n$($_.Exception.Message)"
    }
}

if ($SSHKeyListPath)
{
    Write-Host 'Generating SSH keys...'
    try
    {
        $SSHKeysToCreate = Import-Csv -Path $SSHKeyListPath
        $SSHKeys = $SSHKeysToCreate | New-SSHKeyPair -Force:($PSBoundParameters['Force'] -eq $true)
        Write-Debug ($SSHKeys | Out-String)
    }
    catch
    {
        throw "Failed to generate SSH keys.`n$($_.Exception.Message)"
    }
}

if ($VCSRepoListPath)
{
    try
    {
        $VCSReposToClone = Import-Csv -Path $VCSRepoListPath
        $VCSReposToClone | Copy-VCSRepos
    }
    catch
    {
        throw "Failed to clone VCS repositories.`n$($_.Exception.Message)"
    }
}

if ($SetGlobalGitConfig)
{
    try
    {
        $SetParams = @{}
        if ($GitEmail)
        {
            $SetParams.Add('GitEmail', $GitEmail)
        }
        if ($GitUsername)
        {
            $SetParams.Add('GitName', $GitUsername)
        }
        if ($GenerateGitHubGPGKey)
        {
            $SetParams.Add('GitSignCommits', $true)
            $GPGPath = (Get-Command 'gpg' | Convert-Path) -replace '\\', '/'
            $SetParams.Add('GitSigningApplicationPath', $GPGPath)
            if ($GPGKey)
            {
                $SetParams.Add('GitSigningKey', $GPGKey)
            }
        }
        Set-GlobalGitConfig @SetParams
    }
    catch
    {
        throw $_.Exception.Message
    }
}

try
{
    Enable-RunAsOnStartMenu
}
catch
{
    throw $_.Exception.Message
}