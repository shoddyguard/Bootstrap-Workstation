function Add-GitHubGPGKey
{
    [CmdletBinding()]
    param
    (
        # The GPG key to be added to GitHub
        [Parameter(Mandatory = $true)]
        [string[]]
        $GPGKey,

        # The GitHub Token to use for adding the GPG key
        [Parameter(Mandatory = $true)]
        [string]
        $GitHubToken
    )
    
    begin
    {
        $Headers = @{
            'Authorization' = "token $GitHubToken"
            'accept'        = 'application/vnd.github.v3+json'
        }
        $URI = 'https://api.github.com/user/gpg_keys'
    }
    
    process
    {
        Write-Host "Adding GPG key to GitHub..."
        $GPGKey | ForEach-Object {
            $Body = @{
                'armored_public_key' = ($_ | Out-String)
            }
            Write-Debug ($Body | Out-String)
            try
            {
                Invoke-RestMethod -Uri $URI -Method POST -Headers $Headers -Body ($Body | ConvertTo-Json) | Out-Null
            }
            catch
            {
                throw "Failed to add GPG key.$($_.Exception.Message)"
            }
        }
        Write-Host "GPG key successfully added to GitHub." -ForegroundColor Green
    }
    
    end
    {
        
    }
}