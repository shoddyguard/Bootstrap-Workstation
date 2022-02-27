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

        # An optional comment for the key
        [Parameter(Mandatory = $false)]
        [string]
        $Comment,

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
        if ($Comment)
        {
            $FileContent += "Name-Comment: $Comment`n"
        }
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
            Write-Host "Generating GPG key for $EmailAddress..."
            # Use the Temp PSDrive.
            $TempFile = New-Item -Path (Join-Path 'Temp:' -ChildPath 'GPGKey.txt') -Force -Value $FileContent | Convert-Path
            $Output = & gpg --batch --gen-key $TempFile 2>&1
            Write-Debug "GPG Output:`n$Output"
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to generate the key, non-zero exit code: $LASTEXITCODE" -Category InvalidOperation -ErrorId 'GPGKeyGenerationFailed' -ErrorAction 'Stop'
            }
            $Today = Get-Date -Format yyyy-MM-dd
            $Keys = & gpg --list-secret-keys --keyid-format=long 2>&1 | Where-Object { $_ -match "sec(?:.*)\/(?<keyid>[A-Z0-9]*) $Today" }
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to list the keys, listing keys returned non-zero exit code: $LASTEXITCODE" -Category InvalidOperation -ErrorId 'GPGKeyListingFailed' -ErrorAction 'Stop'
            }
            Write-Debug "Found key(s):`n$($Keys | Out-String)"
            $KeyId = $Matches.keyid
            if ($KeyId.count -gt 1)
            {
                Write-Verbose "Found multiple keys, using the newest one"
                # The most recent key is always at the end of the list
                $KeyId = $KeyId[-1]
            }
            if (!$KeyId)
            {
                Write-Error 'Failed to generate the key, could not find the key' -Category InvalidOperation -ErrorId 'GPGKeyGenerationFailed' -ErrorAction 'Stop'
            }
            $ArmorExport = & gpg --armor --export $KeyID
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to generate the key, armor export returned a non-zero exit code: $LASTEXITCODE" -Category InvalidOperation -ErrorId 'GPGKeyGenerationFailed' -ErrorAction 'Stop'
            }
            $Return = [PSCustomObject]@{
                PublicKey = ($ArmorExport | Out-String)
                KeyId = $KeyId
                Name = $UserName
                Email = $EmailAddress
            }

        }
        catch
        {
            throw $_
        }
        finally
        {
            Remove-Item -Path $TempFile -Force -ErrorAction 'SilentlyContinue'
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
            Return $null
        }
    }
}