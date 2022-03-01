<#
.SYNOPSIS
    This cmdlet installs modules from the PowerShell Gallery.
.DESCRIPTION
    This cmdlet is mostly just a wrapper around the Install-Module cmdlet.
    It helps to keep the bootstrap scripts a little cleaner.
#>
function Install-PSGalleryModule
{
    [CmdletBinding()]
    param
    (
        # The name of the PSGallery module to install.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'default')]
        [string]
        $ModuleName,

        # The version of the PSGallery module to install.
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'default')]
        [version]
        $Version,

        # If set will force the installation of the module even if it is already installed.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force,

        # Special hidden parameter for pipeline support.
        [Parameter(Mandatory = $false, ParameterSetName = 'pipe', ValueFromPipeline = $true, DontShow)]
        [PSGalleryModule[]]
        $InputObject
    )
    
    begin
    {
        Write-Host 'Installing PowerShell Gallery modules...'
    }
    
    process
    {
        
        if (!$InputObject)
        {
            $InputObject = @{
                ModuleName = $ModuleName
            }
            if ($Version)
            {
                $InputObject.ModuleVersion = $Version
            }
        }
        foreach ($Object in $InputObject)
        {
            try
            {
                $Check = Get-Module -ListAvailable $Object.ModuleName
                if ($Object.ModuleVersion)
                {
                    if ($Object.ModuleVersion -eq $Check.Version)
                    {
                        Write-Verbose "Module $($Object.ModuleName) is already installed at version $($Check.Version)"
                        continue
                    }
                    else
                    {
                        Write-Verbose "Module $($Object.ModuleName) is already installed at version $($Check.Version). Installing version $($Object.ModuleVersion)"
                        $Force = $true
                    }
                }
                if ((!$Check) -or ($Force))
                {
                    $InstallParams = @{
                        Name       = $Object.ModuleName
                        Repository = 'PSGallery'
                        Force      = $true # We always use -Force even if we haven't explicitly set it to get around the 'untrusted' dialog. This should be fine as we check the version before installing anyway.
                    }
                    if ($Object.ModuleVersion)
                    {
                        $InstallParams.RequiredVersion = $Object.ModuleVersion
                    }
                    Install-Module @InstallParams
                }
            }
            catch
            {
                throw "Failed to install module '$($Object.ModuleName)' from the gallery."
            }
        }
    }
    
    end
    {
        Write-Host 'Successfully installed PowerShell Gallery modules.' -ForegroundColor Green
    }
}