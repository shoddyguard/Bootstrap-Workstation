function Install-ChocolateyPackage
{
    [CmdletBinding(
        DefaultParameterSetName = 'default'
    )]
    param
    (
        # The name of the package to install
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'default',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageName,

        # The version of the package to install
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = 'default',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageVersion = 'any',

        # If passed will upgrade the package to latest if it's already installed
        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Upgrade,

        # Special param for pipeline usage from things like import-csv
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'pipeline',
            DontShow
        )]
        [ValidateNotNullOrEmpty()]
        [ChocolateyPackage[]]
        $ChocolateyPackages
    )
    
    begin
    {
        if (!$IsWindows)
        {
            throw "Not a Windows system."
        }
        try
        {
            $ChocoCheck = Get-Command 'choco'
        }
        catch {}
        if (!$ChocoCheck)
        {
            throw "Chocolatey does not appear to be installed or is not available on your path.`nYou can run 'Install-Chocolatey' to install Chocolatey on your system"
        }
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            throw "Chocolatey must be run from an elevated PowerShell session."
        }
        $AcceptedVersionStrings = @('any', 'installed', 'present') # A collection of possible package versions strings
        $ValidExitCodes = @(0, 3010, 1641) # 3010 and 1641 are success but restart pending/initiated

        # If we've specified 'upgrade' then grab our list of installed applications and current vs latest versions
        # Doing it this way means we only have to compute it once as opposed to doing it on every single package.
        # It does mean we have to parse Chocolatey's output but that should be fine...
        if ($Upgrade)
        {
            $OutdatedPackages = @()
            try
            {
                $OutdatedArgs = @{
                    FilePath = 'choco'
                    ArgumentList = @('outdated','-r')
                    ExitCodes = $ValidExitCodes
                    PassThru = $true
                    SuppressOut = $true
                }
                if ($VerbosePreference -eq 'Continue')
                {
                    $OutdatedArgs.Remove('SuppressOut')
                }
                Invoke-NativeCommand @OutdatedArgs | Select-Object -ExpandProperty OutputContent |
                    ForEach-Object {
                        # Chocolatey outputs:
                        # package_name|current_version|latest_version|pinned
                        # eg awscli|1.0.0|1.0.1|false
                        # We don't use all this data at present but I've captured it all so that it's there if we need it.
                        $Package = $_.split('|')
                        $OutdatedPackages += [pscustomobject]@{
                            PackageName    = $Package[0]
                            CurrentVersion = $Package[1]
                            LatestVersion  = $Package[2]
                            Pinned         = [System.Convert]::ToBoolean($Package[3])
                        }   
                    }
            }
            catch
            {
                throw "Failed to get a list of upgradable packages.`n$($_.Exception.Message)"
            }
        }
    }
    
    process
    {
        # We cast this to the ChocolateyPackages variable above, as this gets param validation using our ChocolateyPackages class
        # for free! :D
        if (!$ChocolateyPackages)
        {
            $ChocolateyPackages = @{
                Name    = $PackageName
                Version = $PackageVersion
            }
        }
        
        foreach ($ChocolateyPackage in $ChocolateyPackages)
        {
            Write-Verbose "Checking to see if '$($ChocolateyPackage.Name)' is already installed"
            try
            {
                $ListArgs = @{
                    FilePath = 'choco'
                    ArgumentList = @('list', "$($ChocolateyPackage.name)", '-e', '-r', '--local-only')
                    ExitCodes = $ValidExitCodes
                    PassThru = $true
                    SuppressOut = $true
                }
                if ($VerbosePreference -eq 'Continue')
                {
                    $ListArgs.Remove('SuppressOut')
                }
                $testPackage = Invoke-NativeCommand @ListArgs | Select-Object -ExpandProperty OutputContent
            }
            catch
            {
                Write-Error "Failed to determine if '$($ChocolateyPackage.name)' is already installed.`n$($_.Exception.Message)"
                break
            }
            if ($testPackage)
            {
                Write-Verbose "$testPackage is already installed, checking version number"
                # Remove the package name from the output string that  Chocolatey gave us, 
                # which _should_ just leave us with the version string.
                $CurrentVersion = $testPackage -replace "$($ChocolateyPackage.name)\|", ""
                
                # If we've not requested a specific version of a package then see if we're going to upgrade it
                if ($ChocolateyPackage.version -in $AcceptedVersionStrings)
                {
                    if ($Upgrade)
                    {
                        Write-Verbose "Checking to see if $($ChocolateyPackage.name) can be upgraded"
                        if ($OutdatedPackages.PackageName -contains $ChocolateyPackage.name)
                        {
                            Write-Verbose "Package '$($ChocolateyPackage.name)' is outdated, upgrading"
                            try
                            {
                                $UpgradeArgs = @{
                                    FilePath = 'choco'
                                    ArgumentList = @('upgrade', "$($ChocolateyPackage.name)", '-y')
                                    ExitCodes = $ValidExitCodes
                                    SuppressOut = $true
                                }
                                if ($VerbosePreference -eq 'Continue')
                                {
                                    $UpgradeArgs.Remove('SuppressOut')
                                }
                                Invoke-NativeCommand @UpgradeArgs
                            }
                            catch
                            {
                                Write-Error "Failed to upgrade $($ChocolateyPackage.name).`n$($_.Exception.Message)"
                            }
                        }
                    }
                }
                # If we have requested a specific version of a package then make sure it matches what's currently installed
                else
                {
                    Write-Verbose "Checking installed version of '$($ChocolateyPackage.name)' matches version '$($ChocolateyPackage.version)'"
                    if ($ChocolateyPackage.version -ne $CurrentVersion)
                    {
                        Write-Error "Package '$($ChocolateyPackage.name)' has a mismatched version. Version '$($ChocolateyPackage.version)' was requested but version '$CurrentVersion' is installed"
                    }
                    if ($Upgrade)
                    {
                        Write-Warning "Upgrade parameter will not be honoured for package '$($ChocolateyPackage.name)' as it has a specific version set"
                    }
                }
                
            }
            else
            {
                Write-Verbose "Attempting to install '$($ChocolateyPackage.Name)' version '$($ChocolateyPackage.Version)'"
                $InstallArgs = @("install", "$($ChocolateyPackage.name)", "-y")
                if ($ChocolateyPackage.version -notin $AcceptedVersionStrings)
                {
                    $InstallArgs = $InstallArgs + " --version $($ChocolateyPackage.version)"
                }
                try
                {
                    $InstallArgs = @{
                        FilePath = 'choco'
                        ArgumentList = $InstallArgs
                        ExitCodes = $ValidExitCodes
                        SuppressOut = $true
                    }
                    if ($VerbosePreference -eq 'Continue')
                    {
                        $InstallArgs.Remove('SuppressOut')
                    }
                    Invoke-NativeCommand @InstallArgs
                }
                catch
                {
                    Write-Error "Failed to install package '$($ChocolateyPackage.name)'.`n$($_.Exception.Message)"
                }
            }
        }
    }
    end
    {
        # Reload the path so we can find any packages we've installed
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
    }
}