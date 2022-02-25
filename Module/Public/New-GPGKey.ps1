<#
.SYNOPSIS
    Generates a GPG key and uploads it to GitHub.
.DESCRIPTION
    This cmdlet will generate a GPG key and upload it to GitHub.
    It will also set the global signing key to the newly generated key if desired.
#>
function New-GPGKey
{
    [CmdletBinding()]
    param
    (
        # The name of the user
        [Parameter(Mandatory = $true)]
        [string]
        $UserName,

        # The email address of the user
        [Parameter(Mandatory = $true)]
        [string]
        $EmailAddress,

        # The GitHub token for uploading the key
        [Parameter(Mandatory = $true)]
        [string]
        $GitHubToken,

        # An optional passphrase for the key
        [Parameter(Mandatory = $false)]
        [securestring]
        $Passphrase,

        # An optional comment for the key
        [Parameter(Mandatory = $false)]
        [string]
        $Comment,

        # The length of the key
        [Parameter(Mandatory = $false)]
        [int]
        $Length = 4096,

        # If set will enable the key to be used for signing globally
        [Parameter(Mandatory = $false)]
        [switch]
        $EnableGlobalSigning
    )
    
    begin
    {
        try
        {
            $GPGCheck = Get-Command gpg
            $GitCheck = Get-Command git
            if (!$GPGCheck -or !$GitCheck)
            {
                Write-Error 'GPG and/or Git are not installed, have you run the prep script?'
            }
        }
        catch
        {
            throw $_
        }
    }
    
    process
    {
        try
        {
            $GenerateArgs = @{
                UserName = $UserName
                EmailAddress = $EmailAddress
                length = $Length
            }
            if ($Passphrase)
            {
                $GenerateArgs.Add('Passphrase',$Passphrase)
            }
            if ($Comment)
            {
                $GenerateArgs.Add('Comment',$Comment)
            }
            # Generate the key
            $Key = New-GeneratedGPGKey @GenerateArgs
            # Add it to GitHub
            Add-GitHubGPGKey -GitHubToken $GitHubToken -GPGKey $Key.PublicKey
            if ($EnableGlobalSigning)
            {
                Write-Host "Setting global signing key to $($Key.KeyID)"
                & git config --global user.signingkey $Key.KeyId
                if ($LASTEXITCODE -ne 0)
                {
                    Write-Error "Failed to set global signing key, git returned a non-zero exitcode: $LASTEXITCODE"
                }
                Write-Host "Successfully set global signing key to $($Key.KeyId)" -ForegroundColor Green
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