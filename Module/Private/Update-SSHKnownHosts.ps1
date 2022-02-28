function Update-SSHKnownHosts
{
    [CmdletBinding()]
    param
    (
        # The URI of the remote host to add to the known hosts file.
        [Parameter(Mandatory = $true)]
        [string]
        $URI    
    )
    
    $AddKey = $true
    # Right now don't bother doing a lookup for HTTP/S stuff
    if ($URI -match '^http')
    {
        Write-Verbose "'$URI' appears to be a URL, skipping host lookup"
        Return
    }
    # Try to match on 'user@host'
    if ($URI -match '\b(?:[\w\.-]+)@(?<domain>(?:[\w\-]+)(?:\.\w{2,4})(?:\.\w{2,4})?\b)')
    {
        $Hostname = $matches['domain']
    }
    else
    {
        $Hostname = $URI 
    }
    $KnownHostsFile = Join-Path $HOME '.ssh' 'known_hosts'
    if (!(Test-Path $KnownHostsFile))
    {
        New-Item -Path $KnownHostsFile -ItemType File -Force | Out-Null
    }
    else
    {
        $KnownHostsContent = Get-Content $KnownHostsFile -Raw
        if ($KnownHostsContent -match [Regex]::Escape($Hostname))
        {
            Write-Verbose "Host '$Hostname' is already in '$KnownHostsFile'"
            $AddKey = $false
        }
    }
    if ($AddKey -eq $true)
    {
        Write-Host "Adding '$Hostname' to '$KnownHostsFile'"
        try
        {
            $KeyScan = Invoke-NativeCommand -FilePath 'ssh-keyscan' -ArgumentList @($Hostname) -PassThru -SuppressOutput | Select-Object -ExpandProperty 'OutputContent'
            if ($KeyScan)
            {
                Add-Content $KnownHostsFile ($KeyScan | Out-String)
            }
        }
        catch
        {
            throw "Failed to add '$Hostname' to '$KnownHostsFile'.`n$($_.Exception.Message)"
        }
    }
}