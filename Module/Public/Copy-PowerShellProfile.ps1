<#
.SYNOPSIS
    Copies a PowerShell profile and applies it to the current user.
.DESCRIPTION
    Copies a PowerShell profile and applies it to the current user.
#>
function Copy-PowerShellProfile
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
        Write-Host "Setting up PowerShell profile..."
    }
    
    process
    {
        try
        {
            $File = Get-File -Path $Path -ErrorAction 'Stop'
            $Content = Get-Content $File -Raw -ErrorAction 'Stop'
            if ((Test-Path $PROFILE))
            {
                if ($Force)
                {
                    Set-Content -Path $PROFILE -Value $Content -Force -ErrorAction 'Stop'
                }
                else
                {
                    Write-Warning "The profile '$PROFILE' already exists, use the '-Force' parameter to overwrite it."
                }
            }
            else
            {
                New-Item -Path $PROFILE -ItemType File -Force -Value $Content | Out-Null
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
                    $WindowsProfile = "C:\Users\$env:USERNAME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
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
            throw "Failed to update PowerShell profile.`n$($_.Exception.Message)"
        }
    }
    
    end
    {
        Write-Host "PowerShell profile setup complete." -ForegroundColor Green
    }
}