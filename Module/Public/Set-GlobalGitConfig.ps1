<#
.SYNOPSIS
    Sets certain git global configuration options.
.DESCRIPTION
    Sets certain git global configuration options.
#>
function Set-GlobalGitConfig
{
    [CmdletBinding()]
    param
    (
        # The email address of the user
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitEmail,

        # The name of the user
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitName,

        # The signing key to use
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitSigningKey,

        # The path to the signing application
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitSigningApplicationPath,

        # If set will sign commits by default
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [bool]
        $GitSignCommits,

        # If set will change the default ssh application
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitSSHApplicationPath
    )
    
    begin
    {
        
    }
    
    process
    {
        try
        {
            Write-Host 'Setting global git config'
            if ($GitEmail)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'user.email', $GitEmail)
            }
            if ($GitName)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'user.name', $GitName)
            }
            if ($GitSigningKey)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'user.signingkey', $GitSigningKey)
            }
            if ($GitSigningApplicationPath)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'gpg.program', $GitSigningApplicationPath)
            }
            if ($GitSignCommits)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'commit.gpgsign', 'true')
            }
            if ($GitSSHApplicationPath)
            {
                Invoke-NativeCommand -FilePath 'git' -ArgumentList @('config', '--global', 'core.sshcommand', $GitSSHApplicationPath)
            }
        }
        catch
        {
            throw "Failed to set global git config.`n$($_.Exception.Message)"
        }
        Write-Host 'Successfully set global git config' -ForegroundColor Green
    }
    
    end
    {
        
    }
}