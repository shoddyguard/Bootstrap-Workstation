# Some types/classes for our SSH key cmdlets
class SSHKey
{
    [string]$KeyName
    [string]$KeyType
    [string]$KeyPath
    [int]$KeyBits
    [string]$KeyPassphrase
    [string]$KeyComment

    # This constructor is used to create a new key from a custom object (useful for ingesting CSV files and the like)
    SSHKey([pscustomobject]$SSHKey)
    {
        # Mandatory properties
        $this.KeyName = $SSHKey.KeyName
        $this.KeyType = $SSHKey.KeyType

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
        if ($SSHKey.KeyPassphrase)
        {
            $this.KeyPassphrase = $SSHKey.KeyPassphrase
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
        if ($SSHKey.KeyPassphrase)
        {
            $this.KeyPassphrase = $SSHKey.KeyPassphrase
        }
        if ($SSHKey.KeyComment)
        {
            $this.KeyComment = $SSHKey.KeyComment
        }
    }
}