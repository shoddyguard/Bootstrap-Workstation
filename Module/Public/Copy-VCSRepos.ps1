<#
.SYNOPSIS
    Clones a given set of VCS repositories.
.DESCRIPTION
    Clones a given set of VCS repositories.
#>
function Copy-VCSRepos
{
    [CmdletBinding()]
    param
    (
        # The VCS repositories to clone.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [VCSRepo[]]
        $VCSRepos,

        # The destination directory.
        [Parameter(Mandatory = $false)]
        [string]
        $Path = (Join-Path $HOME 'Repositories'),

        # If set denotes that the SSH key requires a passphrase.
        [Parameter(Mandatory = $false)]
        [bool]
        $PassphraseRequired = $false
    )
    
    begin
    {
        Write-Host 'Cloning VCS repositories...'
    }
    
    process
    {
        foreach ($VCSRepo in $VCSRepos)
        {
            $ClonePath = $Path
            try
            {
                $CloneParams = @{
                    URI = $VCSRepo.RepoURI
                }
                if ($VCSRepo.LocalPath)
                {
                    $ClonePath = $VCSRepo.LocalPath
                }
                if ($VCSRepo.ParentDirectory)
                {
                    $ClonePath = Join-Path $ClonePath $VCSRepo.ParentDirectory
                }
                $CloneParams.Path = $ClonePath
                if ($VCSRepo.RepoName)
                {
                    $CloneParams.Name = $VCSRepo.RepoName
                }
                # First perform a keyscan to make sure we can clone the repo without any errors.
                Update-SSHKnownHosts -URI $VCSRepo.RepoURI
                Copy-VCSRepo @CloneParams
            }
            catch
            {
                throw "Failed to clone VCS repository '$($VCSRepo.RepoURI)'.`n$($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        Write-Host 'Finished cloning VCS repositories.' -ForegroundColor Green
    }
}