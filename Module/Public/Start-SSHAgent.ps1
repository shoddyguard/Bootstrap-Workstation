<#
.SYNOPSIS
    Starts the SSH-Agent
#>
function Start-SSHAgent
{
    [CmdletBinding()]
    param
    (
        
    )
    
    begin
    {
        
    }
    
    process
    {
        if ($IsWindows)
        {
            
            try
            {
                $SSHAgentService = Get-Service -Name 'ssh-agent'
                if ($SSHAgentService.Status -ne 'Running')
                {
                    $SSHAgentService | Set-Service -StartupType Manual
                    Start-Service ssh-agent
                }
            }
            catch
            {
                throw "Failed to start the SSH-Agent service.`n$($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        
    }
}