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
        [Parameter(Mandatory = $true)]
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
            $GenerateParams = @{
                Path    = $Path
                KeyType = 'ed25519'
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
                Token        = $GitHubToken
                SSHPublicKey = $KeyInfo.PublicKey
            }
            if ($Comment)
            {
                $GitHubParams.Add('Title', $Comment)
            }
            Add-GitHubSSHKey @GitHubParams
            # Because we're creating a bit of a weird key for GitHub, we need to tell SSH to use it
            # instead of the default key.
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