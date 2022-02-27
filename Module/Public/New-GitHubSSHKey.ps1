<#
.SYNOPSIS
    Creates a key-pair that can be used to authenticate to GitHub.
.DESCRIPTION
    Creates an SSH key pair and uploads the public key to GitHub.
#>
function New-GitHubSSHKey
{
    [CmdletBinding()]
    param
    (
        # The path to store the key-pair.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        # The token to use to authenticate to GitHub. (must have correct permissions)
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitHubToken,

        # An optional description for the key-pair.
        [Parameter(Mandatory = $false)]
        [string]
        $Comment,

        # An optional passphrase for the key-pair.
        [Parameter(Mandatory = $false)]
        [securestring]
        $Passphrase


    )
    
    begin
    {
        
    }
    
    process
    {
        try
        {
            Write-Host "Creating a new ssh key pair for GitHub..."
            $GenerateParams = @{
                Name = "github"
                KeyType = 'ed25519'
            }
            if ($Path)
            {
                $GenerateParams.Add('Path', $Path)
            }
            if ($Comment)
            {
                $GenerateParams.Add('Comment', $Comment)
            }
            if ($Passphrase)
            {
                $GenerateParams.Add('Passphrase', $Passphrase)
            }
            $KeyInfo = New-SSHKeyPair @GenerateParams
            $GitHubParams = @{
                GitHubToken  = $GitHubToken
                SSHPublicKey = $KeyInfo.PublicKey
            }
            if ($Comment)
            {
                $GitHubParams.Add('Title', $Comment)
            }
            Add-GitHubSSHKey @GitHubParams
            # GitHub doesn't like it when you don't use the default key for SSH, so we'll add it to the user's config.
            Write-Host "Setting the new key as the explicit key for github.com..."
            Add-SSHHostEntry -HostName 'github.com' -IdentityFile $KeyInfo.PrivateKeyPath
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