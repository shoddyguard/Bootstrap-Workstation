<#
.SYNOPSIS
    Generates a GPG key and uploads it to GitHub.
.DESCRIPTION
    This cmdlet will generate a GPG key and upload it to GitHub.
    It will also set the global signing key to the newly generated key if desired.
#>
function New-GitHubGPGKey
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
        [Alias('Email')]
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
        $EnableGlobalSigning,

        # If set will forcefully overwrite an existing key
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    
    begin
    {
        try
        {
            $GPGCheck = Get-Command gpg -ErrorAction Stop
            $GitCheck = Get-Command git -ErrorAction Stop
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
                UserName     = $UserName
                EmailAddress = $EmailAddress
                length       = $Length
            }
            if ($Passphrase)
            {
                $GenerateArgs.Add('Passphrase', $Passphrase)
            }
            if ($Comment)
            {
                $GenerateArgs.Add('Comment', $Comment)
            }
            if ($Force)
            {
                $GenerateArgs.Add('Force', $true)
            }
            # Generate the key
            $Key = New-GeneratedGPGKey @GenerateArgs
            # Only upload the key if we've generated a new one (we may not have done if we've already uploaded it)
            if ($Key)
            {
                # Add it to GitHub
                Add-GitHubGPGKey -GitHubToken $GitHubToken -GPGKey $Key.PublicKey
                $Return = $Key.KeyID
            }
        }
        catch
        {
            throw $_
        }
    }
    
    end
    {
        if ($Return)
        {
            Return $Return
        }
        else
        {
            return $null
        }

    }
}