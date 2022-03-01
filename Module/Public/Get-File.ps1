<#
.SYNOPSIS
    Gets a file that is either local or remote.
.DESCRIPTION
    This cmdlet will check to see if the file is local or remote. If it is local, it will return the file. 
    If it is remote, it will download the file and return it.
    This has the added benefit of ensuring the file exists before returning it.
#>
function Get-File
{
    [CmdletBinding()]
    param
    (
        # The path to the file to get.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Path
    )
    
    begin
    {
        
    }
    
    process
    {
        if ($Path -match '^http(s)?://')
        {
            # First we need to download the file to a temporary location.
            try
            {
                Write-Verbose "Attempting to download '$Path' to a temporary location."
                $TempFile = New-TemporaryFile | Convert-Path
                # Create a HTTPClient to download the file.
                $HTTPClient = New-Object System.Net.Http.HttpClient
                $Response = $HTTPClient.GetAsync($Path)
                $Response.Wait()
                # Create a FileStream to write the file to.
                $Output = [System.IO.FileStream]::new($TempFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                # Write the file to the FileStream.
                $Download = $Response.Result.Content.CopyToAsync($Output)
                $Download.Wait()
                # Close the FileStream.
                $Output.Close()
                $Return = $TempFile
            }
            catch
            {
                throw "Failed to download '$Path'.`n$($_.Exception.Message)"
            }
        }
        else
        {
            try
            {
                Write-Verbose "Attempting to get '$Path' from the local file system."
                $Item = Get-Item $Path | Convert-Path
                $Return = $Item
            }
            catch
            {
                throw "Failed to get local path '$Path'.`n$($_.Exception.Message)"
            }
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