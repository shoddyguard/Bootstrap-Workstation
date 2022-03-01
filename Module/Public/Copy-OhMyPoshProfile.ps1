<#
.SYNOPSIS
    Copies an Oh-My-Posh theme to the user's home directory.
.DESCRIPTION
    Copies an Oh-My-Posh theme to the user's home directory.
#>
function Copy-OhMyPoshProfile
{
    [CmdletBinding()]
    param
    (
        # The path to the PowerShell profile to copy.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Path,

        # If set will apply the profile to Windows/Desktop PowerShell as well.
        [Parameter(Mandatory = $false)]
        [switch]
        $ApplyToDesktop,

        # If set will forcefully overwrite an existing profile.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    
    begin
    {
        Write-Host "Setting up Oh-My-PoSh profile..."
    }
    
    process
    {
        try
        {
            $File = Get-File -Path $Path -ErrorAction 'Stop'
            $Content = Get-Content $File -Raw -ErrorAction 'Stop'
            $ProfilePath = Join-Path (Get-Item $PROFILE).PSParentPath 'profile.omp.json'
            if ((Test-Path $ProfilePath))
            {
                if ($Force)
                {
                    Set-Content -Path $ProfilePath -Value $Content -Force -ErrorAction 'Stop'
                }
                else
                {
                    Write-Warning "The profile '$ProfilePath' already exists, use the '-Force' parameter to overwrite it."
                }
            }
            else
            {
                New-Item -Path $ProfilePath -ItemType File -Force -Value $Content | Out-Null
            }
            if ($ApplyToDesktop)
            {
                if (!$IsWindows)
                {
                    Write-Warning "The '-ApplyToDesktop' parameter is only supported on Windows."
                }
                else
                {
                    Write-Verbose "Applying profile to Windows/Desktop PowerShell..."
                    $WindowsProfile = "C:\Users\$env:USERNAME\Documents\WindowsPowerShell\profile.omp.json"
                    if ((Test-Path $WindowsProfile))
                    {
                        if ($Force)
                        {
                            Set-Content -Path $WindowsProfile -Value $Content -Force -ErrorAction 'Stop'
                        }
                        else
                        {
                            Write-Warning "The profile '$WindowsProfile' already exists, use the '-Force' parameter to overwrite it."
                        }
                    }
                    else
                    {
                        New-Item -Path $WindowsProfile -ItemType File -Force -Value $Content | Out-Null
                    }
                }
            }
        }
        catch
        {
            throw "Failed to update Oh-My-PoSh profile.`n$($_.Exception.Message)"
        }
    }
    
    end
    {
        Write-Host "Oh-My-PoSh profile setup complete." -ForegroundColor Green
    }
}