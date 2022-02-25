function New-GeneratedGPGKey
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

        # An optional passphrase for the key
        [Parameter(Mandatory = $false)]
        [securestring]
        $Passphrase,

        # The length of the key
        [Parameter(Mandatory = $false)]
        [int]
        $Length = 4096
    )
    
    begin
    {
        $FileContent = @"
Key-Type: 1
Key-Length: $Length
Subkey-Type: 1
Subkey-Length: $Length
Name-Real: $UserName
Name-Email: $EmailAddress
Expire-Date: 0`n
"@
        if ($Passphrase)
        {
            $FileContent += "Passphrase: $Passphrase`n"
        }
        else
        {
            $FileContent += "%no-protection`n"
        }
        $FileContent += "%commit`n"
    }
    
    process
    {
        try
        {
            # Use the Temp PSDrive.
            $TempFile = New-Item -Path (Join-Path 'Temp:' -ChildPath 'GPGKey.txt') -Force -Value $FileContent | Convert-Path
            & gpg --batch --gen-key $TempFile
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to generate the key, non-zero exitcode: $LASTEXITCODE"
            }
            $Today = Get-Date -Format yyyy-MM-dd
            $Keys = & gpg --list-secret-keys --keyid-format=long | Where-Object { $_ -match "sec(?:.*)\/(?<keyid>[A-Z0-9]*) $Today" }
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to list the keys, listing keys returned non-zero exitcode: $LASTEXITCODE"
            }
            Write-Debug ($Keys | Out-String)
            $KeyId = $Matches.keyid
            if ($KeyId.count -gt 1)
            {
                Write-Verbose "Found multiple keys, using the newest one"
                # The most recent key is always at the end of the list
                $KeyId = $KeyId[-1]
            }
            if (!$KeyId)
            {
                Write-Error 'Failed to generate the key, could not find the key'
            }
            $ArmorExport = & gpg --armor --export $KeyID
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to generate the key, armor export returned a non-zero exitcode: $LASTEXITCODE"
            }

        }
        catch
        {
            throw $_
        }    
    }
    
    end
    {
        if ($ArmorExport)
        {
            Return $ArmorExport
        }
        else
        {
            Return $null
        }
    }
}