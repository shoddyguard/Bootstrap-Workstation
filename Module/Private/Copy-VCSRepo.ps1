<#
.SYNOPSIS
    Wrapper cmdlet for cloning a repository.
.DESCRIPTION
    Wrapper cmdlet for cloning a repository.
#>
function Copy-VCSRepo
{
    [CmdletBinding()]
    param
    (
        # The link to download the VCS repo
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [string]
        $URI,

        # The path where to store the VCS repo
        [Parameter(Mandatory = $true, ParameterSetName = 'default')]
        [string]
        $Path,

        # The name of the VCS repo if you want to override it
        [Parameter(Mandatory = $false, ParameterSetName = 'default')]
        [string]
        $Name
    )
    
    begin
    {
        if (!(Test-Path $Path))
        {
            try
            {
                New-Item $Path -type directory -Force | Out-Null
            }
            catch
            {
                throw "The path $Path does not exist and cannot be created.`n$($_.Exception.Message)"
            }
        }
        else
        {
            if ($Name)
            {
                $TestPath = Join-Path $Path $Name
            }
            else
            {
                # Try to work out the path from the URI
                if ($URI -match '(?:http|git@).*\/(?<repoName>.*).git')
                {
                    $TestPath = Join-Path $Path $Matches.repoName
                }
                else
                {
                    $TestPath = Join-Path $Path ($URI | Select-Object -Last 1)
                }
            }
        }
    }
    
    process
    {
        if ((Test-Path $TestPath -ErrorAction 'SilentlyContinue'))
        {
            Write-Verbose "The repo already exists at '$TestPath'"
            Return
        }
        try
        {
            $CloneParams = @('clone', $URI)
            if ($Name)
            {
                $CloneParams += @($Name)
            }
            Invoke-NativeCommand -FilePath 'git' -ArgumentList $CloneParams -WorkingDirectory $Path -SuppressOutput
        }
        catch
        {
            throw "Failed to clone $URI.`n$($_.Exception.Message)"
        }
    }
    
    end
    {
        
    }
}