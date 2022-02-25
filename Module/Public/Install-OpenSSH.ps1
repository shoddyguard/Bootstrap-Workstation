<#
.SYNOPSIS
    Installs the latest version of OpenSSH on Windows machines.
.DESCRIPTION
    On Windows we don't want to use the ancient version of OpenSSH that comes with the OS, so we instead use the version available from GitHub.
.NOTES
    Adapted from June Castillote's guide: https://adamtheautomator.com/openssh-windows/
#>
function Install-OpenSSH
{
    [CmdletBinding()]
    param
    ()
    if (!$IsWindows)
    {
        # We don't need to do anything here.
        Return $null
    }
    else
    {
        Write-Host "Installing OpenSSH for Windows..."
        try
        {
            $Url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
            $TempPath = Join-Path $env:temp 'OpenSSH-Win64.zip'
            $Request = [System.Net.WebRequest]::Create($Url)
            $Request.AllowAutoRedirect = $false
            $Response = $Request.GetResponse()
            $Source = $([String]$Response.GetResponseHeader('Location')).Replace('tag', 'download') + '/OpenSSH-Win64.zip'
            $webClient = [System.Net.WebClient]::new()
            $webClient.DownloadFile($Source, $TempPath)
            Expand-Archive -Path $TempPath -DestinationPath ($env:temp) -Force
            # Move the extracted ZIP contents from the temporary location to C:\Program Files\OpenSSH\
            Move-Item "$($env:temp)\OpenSSH-Win64" -Destination 'C:\Program Files\OpenSSH\' -Force
            # Unblock the files in C:\Program Files\OpenSSH\
            Get-ChildItem -Path 'C:\Program Files\OpenSSH\' | Unblock-File
            # Run the installer
            & 'C:\Program Files\OpenSSH\install-sshd.ps1'
    
            ## changes the sshd service's startup type from manual to automatic.
            Set-Service sshd -StartupType Automatic
            ## starts the sshd service.
            Start-Service sshd
        }
        catch
        {
            throw "Failed to install OpenSSH.`n$($_.Exception.Message)"
        }
        Write-Host "OpenSSH for Windows has been installed." -ForegroundColor Green
    }
}