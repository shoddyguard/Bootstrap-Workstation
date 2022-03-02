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

        # If set will password protect the key-pair.
        [Parameter(Mandatory = $false)]
        [bool]
        $PassphraseProtected = $false,

        # If set will forcefully overwrite an existing key-pair.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    
    begin
    {
        
    }
    
    process
    {
        try
        {
            $GenerateParams = @{
                Name    = 'github'
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
            if ($PassphraseProtected)
            {
                $GenerateParams.Add('PassphraseProtected', $PassphraseProtected)
            }
            if ($Force)
            {
                $GenerateParams.Add('Force', $true)
            }
            $KeyInfo = New-SSHKeyPair @GenerateParams
            # Only try to add a key to GitHub if one was created.
            # Otherwise, it's likely the key already exists.
            if ($KeyInfo)
            {
                Write-Host 'Created a new ssh key pair for GitHub...'
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
                Write-Host 'Setting the new key as the explicit key for github.com...'
                Add-SSHHostEntry -HostName 'github.com' -IdentityFile $KeyInfo.PrivateKeyPath
                # If the key is passphrase protected, we'll need to add it to ssh-agent so we can clone with it later on.
                if ($PassphraseProtected)
                {
                    Write-Host 'Adding key to ssh-agent, you will be prompted for your passphrase...'
                    Start-SSHAgent
                    Invoke-NativeCommand -FilePath 'ssh-add' -ArgumentList $KeyInfo.PrivateKeyPath
                }
            }
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