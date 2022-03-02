<#
.SYNOPSIS
    Creates an SSH key pair.
.DESCRIPTION
    Creates an SSH key pair.
#>
function New-SSHKeyPair
{
    [CmdletBinding(
        DefaultParameterSetName = 'default'
    )]
    param
    (
        # The name of the key
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        # The type of key pair to create.
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [ValidateSet('rsa', 'dsa', 'ecdsa', 'ed25519')]
        [string]
        $KeyType,

        # The path of where the key file should live.
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [string]
        $Path,

        # The bits of the key.
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [int]
        $Bits = 4096,

        # If set will create a passphrase protected key.
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [bool]
        $PassphraseProtected = $false,

        # The comment to associate with the key (optional).
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [string]
        $Comment,

        # If set will forcefully overwrite the key if it already exists.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force,

        # Special param for pipeline usage from things like import-csv
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'pipeline',
            DontShow
        )]
        [ValidateNotNullOrEmpty()]
        [SSHKey[]]
        $SSHKeys
    )
    
    begin
    {
        $SSHCheck = Get-Command 'ssh-keygen' -ErrorAction 'SilentlyContinue'
        if (!$SSHCheck)
        {
            throw 'SSH is not installed on the computer'
        }
        $CreatedKeys = @()
    }
    
    process
    {
        if (!$SSHKeys)
        {
            # Build up a hashtable using our special class.
            $SSHKeyObject = @{
                KeyName = $Name
                KeyType = $KeyType
            }
            if ($Path)
            {
                $SSHKeyObject.add('KeyPath', $Path)
            }
            if ($Bits)
            {
                $SSHKeyObject.add('KeyBits', $Bits)
            }
            if ($PassphraseProtected)
            {
                $SSHKeyObject.add('SetPassphrase', $PassphraseProtected)
            }
            if ($Comment)
            {
                $SSHKeyObject.add('KeyComment', $Comment)
            }
            # Convert the hashtable to an object, so we can process it.
            $SSHKeys = [pscustomobject]$SSHKeyObject
        }
        foreach ($SSHKey in $SSHKeys)
        {
            try
            {
                if (!$SSHKey.Path)
                {
                    $SSHKeyPath = Join-Path $HOME '.ssh'
                }
                else
                {
                    $SSHKeyPath = $SSHKey.Path
                }
                if (!(Test-Path $SSHKeyPath))
                {
                    New-Item -Path $SSHKeyPath -ItemType Directory -Force | Out-Null
                }
                $FullPath = Join-Path $SSHKeyPath $SSHKey.KeyName
                if ((Test-Path $FullPath))
                {
                    if ($Force)
                    {
                        Write-Warning ("The key file at '$FullPath' already exists, it will be overwritten")
                        Write-Host "Removing existing private key file at '$FullPath'" -ForegroundColor Yellow
                        Remove-Item $FullPath -Force
                        # Check for and delete the public key too
                        if ((Test-Path "$FullPath.pub"))
                        {
                            Write-Host "Removing existing public key file at '$FullPath.pub'" -ForegroundColor Yellow
                            Remove-Item "$FullPath.pub" -Force
                        }
                    }
                    else
                    {
                        # Don't overwrite the key
                        Write-Verbose "Key file at '$FullPath' already exists, use -Force to overwrite"
                        Return
                    }
                }
                $SSHArgs = @('-t', $SSHKey.KeyType, '-b', $SSHKey.KeyBits, '-f', $FullPath)
                if ($SSHKey.SetPassPhrase)
                {
                    $Passphrase = Read-Host "Enter passphrase you want to use to secure the key '$($SSHKey.KeyName)'" -AsSecureString
                    $SSHArgs += @('-N', "$($Passphrase | ConvertFrom-SecureString -AsPlainText)")
                }
                else
                {
                    $SSHArgs += @('-N', '""')
                }
                if ($SSHKey.Comment)
                {
                    $SSHArgs += @('-C', $SSHKey.Comment)
                }
                $SSHArgs += @('-q')
                Write-Host "Creating key pair at $FullPath"
                & 'ssh-keygen' $SSHArgs
                if ($LASTEXITCODE -ne 0)
                {
                    Write-Error ("Failed to create key pair at '$FullPath'") -Category InvalidResult -ErrorAction 'Stop'
                }
                $PrivateKeyPath = Get-Item -Path $FullPath | Convert-Path
                $PublicKeyPath = Get-Item -Path ("$PrivateKeyPath" + '.pub')
                $PublicKey = Get-Content $PublicKeyPath
                $CreatedKeys += @{
                    PrivateKeyPath = $PrivateKeyPath
                    PublicKeyPath  = $PublicKeyPath
                    PublicKey      = $PublicKey
                }
            }
            catch
            {
                throw $_
            }
        }
        if ($CreatedKeys.Count -gt 0)
        {
            $Return = $CreatedKeys
        }
    }
    
    end
    {
        if ($Return)
        {
            return $Return
        }
        else
        {
            return $null
        }
    }
}