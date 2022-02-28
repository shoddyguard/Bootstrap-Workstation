<#
.SYNOPSIS
    Adds "Run as another user" to the right-click context menu on the Windows Start menu for the current user.
#>
function Enable-RunAsOnStartMenu
{
    [CmdletBinding()]
    param
    ()
    
    begin
    {
        
    }
    
    process
    {
        if ($IsWindows)
        {
            Write-Host "Enabling 'Run as another user' for the current user's Start menu..."
            $RegPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
            $Name = 'ShowRunAsDifferentUserInStart'
            $Value = 1
            try
            {
                if (!(Test-Path $RegPath))
                {
                    New-Item $RegPath
                }
                New-ItemProperty -Path $RegPath -Name $Name -Value $Value -Force
            }
            catch
            {
                throw "Failed to set registry value.`n$($_.Exception.Message)"
            }
            Write-Host "Enabled 'Run as another user' for the current user's Start menu. A restart is required for the change to take effect." -ForegroundColor Green
        }
    }
    
    end
    {
        
    }
}