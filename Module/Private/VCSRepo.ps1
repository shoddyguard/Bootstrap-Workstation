class VCSRepo
{
    [string]$RepoURI
    [String]$LocalPath
    [String]$ParentDirectory
    [String]$RepoName

    VCSRepo([pscustomobject]$VCSRepo)
    {
        $this.RepoURI = $VCSRepo.RepoURI
        if ($VCSRepo.LocalPath)
        {
            $this.LocalPath = $VCSRepo.LocalPath
        }
        if ($VCSRepo.ParentDirectory)
        {
            $this.ParentDirectory = $VCSRepo.ParentDirectory
        }
        if ($VCSRepo.RepoName)
        {
            $this.RepoName = $VCSRepo.RepoName
        }
    }
    VCSRepo([hashtable]$VCSRepo)
    {
        $this.RepoURI = $VCSRepo.RepoURI
        if ($VCSRepo.LocalPath)
        {
            $this.LocalPath = $VCSRepo.LocalPath
        }
        if ($VCSRepo.ParentDirectory)
        {
            $this.ParentDirectory = $VCSRepo.ParentDirectory
        }
        if ($VCSRepo.RepoName)
        {
            $this.RepoName = $VCSRepo.RepoName
        }
    }
}