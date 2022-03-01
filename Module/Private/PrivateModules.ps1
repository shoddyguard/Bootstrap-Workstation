class PrivateModule
{
    [string]$ModuleName
    [version]$ModuleVersion
    [string]$RepositoryName
    [string]$RepositoryURL

    PrivateModule([pscustomobject]$PrivateModule)
    {
        $this.ModuleName = $PrivateModule.ModuleName
        if ($PrivateModule.ModuleVersion)
        {
            $this.ModuleVersion = $PrivateModule.ModuleVersion
        }
        $this.RepositoryName = $PrivateModule.RepositoryName
        $this.RepositoryURL = $PrivateModule.RepositoryURL
    }

    PrivateModule([hashtable]$PrivateModule)
    {
        $this.ModuleName = $PrivateModule.ModuleName
        if ($PrivateModule.ModuleVersion)
        {
            $this.ModuleVersion = $PrivateModule.ModuleVersion
        }
        $this.RepositoryName = $PrivateModule.RepositoryName
        $this.RepositoryURL = $PrivateModule.RepositoryURL
    }
}