function New-SSHKeyPair
{
    [CmdletBinding()]
    param
    (
        # The type of key pair to create.
        [Parameter(Mandatory = $true)]
        [ValidateSet('rsa', 'dsa', 'ecdsa', 'ed25519')]
        [string]
        $KeyType,

        # The path to the key file.
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # The bits of the key.
        [Parameter(Mandatory = $false)]
        [int]
        $Bits = 2048,

        # The passphrase to protect the key (optional).
        [Parameter(Mandatory = $false)]
        [securestring]
        $Passphrase,

        # The comment to associate with the key (optional).
        [Parameter(Mandatory = $false)]
        [string]
        $Comment
    )
    
    begin
    {
        $SSHCheck = Get-Command 'ssh-keygen' -ErrorAction 'SilentlyContinue'
        if (!$SSHCheck)
        {
            throw 'SSH is not installed on the computer'
        }
    }
    
    process
    {
        try
        {
            $SSHArgs = @('-t', $KeyType, '-b', $Bits, '-f', $Path)
            if ($Passphrase)
            {
                $SSHArgs += @('-N', $Passphrase)
            }
            else
            {
                $SSHArgs += @('-N', '""')
            }
            if ($Comment)
            {
                $SSHArgs += @('-C', $Comment)
            }
            if ((Test-Path $Path))
            {
                Write-Warning ("The key file at '$Path' already exists, it will be overwritten")
                Remove-Item $Path -Force
                # Check for and delete the public key too
                if ((Test-Path "$Path.pub"))
                {
                    Remove-Item "$Path.pub" -Force
                }
            }
            $SSHArgs += @('-q')
            Write-Host "Creating key pair at $Path"
            & 'ssh-keygen' $SSHArgs
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error ("Failed to create key pair at '$Path'") -Category InvalidResult -ErrorAction 'Stop'
            }
            $PrivateKeyPath = Get-Item -Path $Path | Convert-Path
            $PublicKeyPath = Get-Item -Path ("$PrivateKeyPath" + '.pub')
            $PublicKey = Get-Content $PublicKeyPath
            $Return = @{
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