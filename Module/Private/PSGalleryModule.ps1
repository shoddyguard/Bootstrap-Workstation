class PSGalleryModule
{
    [string]$ModuleName
    [version]$ModuleVersion

    PSGalleryModule([pscustomobject]$PSGalleryModule)
    {
        $this.ModuleName = $PSGalleryModule.ModuleName
        if ($PSGalleryModule.ModuleVersion)
        {
            $this.ModuleVersion = $PSGalleryModule.ModuleVersion
        }
    }

    PSGalleryModule([hashtable]$PSGalleryModule)
    {
        $this.ModuleName = $PSGalleryModule.ModuleName
        if ($PSGalleryModule.ModuleVersion)
        {
            $this.ModuleVersion = $PSGalleryModule.ModuleVersion
        }
    }
}