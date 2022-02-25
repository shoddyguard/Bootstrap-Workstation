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
        $GPGKey | ForEach-Object {
            $Body = @{
                'armored_public_key' = $_
            }
            try
            {
                Invoke-RestMethod -Uri $URI -Method POST -Headers $Headers -Body $Body | Out-Null
            }
            catch
            {
                throw "Failed to add GPG key.$($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        
    }
}