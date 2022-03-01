# Some types/classes for our SSH key cmdlets
class SSHKey
{
    [string]$KeyName
    [string]$KeyType
    [string]$KeyPath
    [int]$KeyBits
    [bool]$SetPassPhrase
    [string]$KeyComment

    # This constructor is used to create a new key from a custom object (useful for ingesting CSV files and the like)
    SSHKey([pscustomobject]$SSHKey)
    {
        # Mandatory properties
        $this.KeyName = $SSHKey.KeyName
        $this.KeyType = $SSHKey.KeyType
        if ($SSHKey.KeyType -notin ('rsa', 'dsa', 'ecdsa', 'ed25519'))
        {
            throw "Invalid key type: $($SSHKey.KeyType)"
        }

        # Optional properties
        if ($SSHKey.KeyPath)
        {
            $this.KeyPath = $SSHKey.KeyPath
        }
        if ($SSHKey.KeyBits)
        {
            $this.KeyBits = $SSHKey.KeyBits
        }
        else
        {
            $this.KeyBits = 4096
        }
        if ($SSHKey.SetPassPhrase)
        {
            $this.SetPassPhrase = $true
        }
        if ($SSHKey.KeyComment)
        {
            $this.KeyComment = $SSHKey.KeyComment
        }
    }

    # This constructor is used to create a new key from a hashtable
    SSHKey([hashtable]$SSHKey)
    {
        # Mandatory properties
        $this.KeyName = $SSHKey.KeyName
        $this.KeyType = $SSHKey.KeyType
        if ($SSHKey.KeyType -notin ('rsa', 'dsa', 'ecdsa', 'ed25519'))
        {
            throw "Invalid key type: $($SSHKey.KeyType)"
        }

        # Optional properties
        if ($SSHKey.KeyPath)
        {
            $this.KeyPath = $SSHKey.KeyPath
        }
        if ($SSHKey.KeyBits)
        {
            $this.KeyBits = $SSHKey.KeyBits
        }
        else
        {
            $this.KeyBits = 4096
        }
        if ($SSHKey.SetPassPhrase)
        {
            $this.SetPassPhrase = $true
        }
        if ($SSHKey.KeyComment)
        {
            $this.KeyComment = $SSHKey.KeyComment
        }
    }
}