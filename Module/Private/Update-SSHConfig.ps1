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
                New-Item $SSHPath -ItemType File -Force
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