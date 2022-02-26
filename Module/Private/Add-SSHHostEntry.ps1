function Add-SSHHostEntry
{
    [CmdletBinding()]
    param
    (
        # The hostname or IP address of the server
        [Parameter(Mandatory = $true)]
        [string]$Hostname,
        
        # The identity file to use for authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentityFile,

        # The username to use for authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username
    )
    
    begin
    {
        if (!$Username -and !$IdentityFile)
        {
            throw 'Either the username or the identity file must be specified'
        }
    }
    
    process
    {
        Write-Host "Adding SSH host entry for $Hostname"
        $Config = "Host $Hostname`n    HostName $Hostname`n"
        if ($Username)
        {
            $Config += "    User $Username`n"
        }
        if ($IdentityFile)
        {
            $Config += "    IdentityFile $IdentityFile`n    IdentitiesOnly yes`n"
        }
        try
        {
            Update-SSHConfig -Content $Config
        }
        catch
        {
            throw $_
        }
    }
    
    end
    {
        
    }
}