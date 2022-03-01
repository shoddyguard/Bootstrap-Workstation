# Some types/classes for our chocolatey cmdlets
class ChocolateyPackage
{
    [string]$name
    [string]$version

    # This constructor allows us to instantiate the class with a PSCustomObject (useful for ingesting CSV files and the like)
    ChocolateyPackage([pscustomobject]$ChocolateyPackage)
    {
        if (!$ChocolateyPackage.version)
        {
            $this.version = 'any'
        }
        else
        {
            $this.version = $ChocolateyPackage.version
        }
        $this.name = $ChocolateyPackage.name
        $this.VersionCheck()
    }
    # This constructor allows us to instantiate the raw class by passing in the two string values
    ChocolateyPackage([string]$name, [string]$version)
    {
        $this.name = $name
        $this.version = $version
        $this.VersionCheck()
    }
    # This constructor allows us to instantiate the raw class by passing in the just the package name
    ChocolateyPackage([string]$name)
    {
        $this.name = $name
        $this.version = 'any'
    }
    # This constructor allows us to instantiate the class from a hashtable (useful for when we want to create objects on the fly)
    ChocolateyPackage([hashtable]$ChocolateyPackage)
    {
        # If the user hasn't specified a version then we default to 'any'
        if (!$ChocolateyPackage.version)
        {
            $this.version = 'any'
        }
        else
        {
            $this.version = $ChocolateyPackage.version
        }
        $this.VersionCheck()
        $this.name = $ChocolateyPackage.name
    }
    <# 
        A hidden method that performs some rudimentary validation to make sure the value of 'version' is either in our list
        of accepted strings OR is a valid version number
    #>
    hidden VersionCheck()
    {
        if ($this.version -notin @('present', 'any', 'installed'))
        {
            [version]$this.version
        }
    }
}