function Add-GitHubSSHKey
{
    [CmdletBinding()]
    param
    (
        # The SSH public key to be added to GitHub
        [Parameter(Mandatory = $true)]
        [string]
        $SSHPublicKey,

        # A title for the SSH key
        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        # The GitHub Token to use for adding the GPG key
        [Parameter(Mandatory = $true)]
        [string]
        $GitHubToken
    )
    
    begin
    {
        $Headers = @{
            'Accept'        = 'application/vnd.github.v3+json'
            'Authorization' = "token $GitHubToken"
        }
    }
    
    process
    {
        Write-Host "Adding SSH key to GitHub..."
        $Body = @{
            'title' = $Title
            'key'   = $SSHPublicKey
        }
        try
        {
            $Response = Invoke-RestMethod -Uri 'https://api.github.com/user/keys' -Method POST -Headers $Headers -Body ($Body | ConvertTo-Json)
            Write-Debug ($Response | Out-String)
        }
        catch
        {
            throw "Failed to add SSH key to GitHub.`n$($_.Exception.Message)"
        }
        Write-Host "Successfully added SSH key to GitHub." -ForegroundColor Green
    }
    
    end
    {
        
    }
}