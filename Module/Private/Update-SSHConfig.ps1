function Update-SSHConfig
{
    [CmdletBinding()]
    param
    (
        # The content to add to the SSH config file
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Content    
    )
    
    begin
    {
        try
        {
            $SSHPath = Join-Path $HOME '.ssh' 'config'
            if (!(Test-Path $SSHPath))
            {
                New-Item $SSHPath -ItemType File -Force | Out-Null
            }
            $SSHConfig = Get-Content $SSHPath -Raw
        }
        catch
        {
            throw "Unable to read SSH config file at $SSHPath.`n$($_.Exception.Message)"
        }
    }
    
    process
    {
        try
        {
            if ($SSHConfig -match [Regex]::Escape($Content))
            {
                # Don't do anything if the content is already in the file
                return
            }
            $UpdatedConfig = $SSHConfig + $Content
            Set-Content $SSHPath $UpdatedConfig -Force
        }
        catch
        {
            throw "Unable to update SSH config file at $SSHPath.`n$($_.Exception.Message)"
        }
    }
    
    end
    {
        
    }
}