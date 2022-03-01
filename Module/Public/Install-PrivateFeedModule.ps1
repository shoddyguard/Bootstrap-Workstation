<#
.SYNOPSIS
    Installs PowerShell modules from private repositories.
.DESCRIPTION
    Installs PowerShell modules from private repositories.
    If the repository is not found, it will be added to the list of repositories.
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
function Install-PrivateFeedModule
{
    [CmdletBinding()]
    param
    (
        # The name of the module to install
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [string]
        $ModuleName,

        # The version of the module to install
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [version]
        $Version,

        # The repository to install the module from
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [string]
        $RepositoryName,

        # The URL of the repository to install the module from
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [string]
        $RepositoryURL,

        # The credentials to use to access the repository
        [Parameter(Mandatory = $false)]
        [PSCredential]
        $Credential,

        # If set will forcefully overwrite the module if it already exists
        [Parameter(Mandatory = $false)]
        [switch]
        $Force,

        # Special hidden parameter for allowing piping of the module
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, DontShow, ParameterSetName = 'pipeline')]
        [PrivateModule[]]
        $InputObject
    )
    
    begin
    {
        Write-Host 'Setting up private PowerShell modules...'
    }
    
    process
    {
        try
        {
            if (!$InputObject)
            {
                $InputObject = @{
                    ModuleName     = $ModuleName
                    RepositoryName = $RepositoryName
                    RepositoryURL  = $RepositoryURL
                }
                if ($Version)
                {
                    $InputObject.ModuleVersion = $Version
                }
            }
            foreach ($Object in $InputObject)
            {
                if (!$Credential)
                {
                    $Credential = Get-Credential -Message "Enter your credentials for $($Object.RepositoryName)"
                }
                $RepositoryCheck = Get-PSRepository | Where-Object { $_.Name -eq $Object.RepositoryName }
                if (!$RepositoryCheck)
                {
                    Register-PSRepository `
                        -Name $Object.RepositoryName `
                        -SourceLocation $Object.RepositoryURL `
                        -PublishLocation $Object.RepositoryURL `
                        -InstallationPolicy Trusted `
                        -Credential $Credential
                }
                $ModuleCheck = Get-Module -ListAvailable | Where-Object { $_.Name -eq $Object.ModuleName }
                if ($Object.Version)
                {
                    if ($Object.Version -eq $ModuleCheck.Version)
                    {
                        Write-Verbose "Module $ModuleName is already installed with version $($ModuleCheck.Version)"
                    }
                    else
                    {
                        Write-Verbose "Module $ModuleName is already installed with version $($ModuleCheck.Version) but the version specified is $($Object.Version)"
                        $Force = $true
                    }
                }
                if ((!$ModuleCheck) -or ($Force))
                {
                    $ModuleParams = @{
                        Name       = $Object.ModuleName
                        Repository = $Object.RepositoryName
                        Force      = $true
                        Credential = $Credential
                    }
                    if ($Object.Version)
                    {
                        $ModuleParams.RequiredVersion = $Object.Version
                    }
                    Install-Module @ModuleParams
                }
            }
        }
        catch
        {
            throw "Failed to install module $ModuleName.`n$($_.Exception.Message)"
        }
    }
    
    end
    {
        Write-Host 'Finished setting up private PowerShell modules.' -ForegroundColor Green
    }
}