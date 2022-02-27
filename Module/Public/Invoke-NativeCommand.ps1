function Invoke-NativeCommand
{
    [CmdletBinding()]
    param
    (
        # The path to the command to run
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string]
        [Alias('PSPath')]
        $FilePath,

        # An optional list of arguments to pass to the command
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1
        )]
        [Alias('Arguments')]
        [array]
        $ArgumentList,

        # The working directory to run the command in
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $WorkingDirectory,

        # The allowed exit codes for the command
        [Parameter(
            Mandatory = $false,
            Position = 3
        )]
        [array]
        $ExitCodes = @(0),

        # If passed, will return the output of the command as a PowerShell object
        [Parameter()]
        [switch]
        $PassThru,
        
        # If set output will be suppressed
        [Parameter()]
        [switch]
        $SuppressOutput,

        # The path to where the redirected output should be stored
        # Defaults to the contents of the environment variable 'RepoLogDirectory' if available
        # If that isn't set then defaults to a temp directory
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $RedirectOutputPath,

        # The prefix to use on the redirected streams, defaults to the command run time
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $RedirectOutputPrefix,

        # The suffix for the redirected streams (defaults to log)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $RedirectOutputSuffix = 'log'
    )
    
    begin
    {
        if (('RedirectOutputPath' -in $PSBoundParameters.Keys) -or ('RedirectOutputPrefix' -in $PSBoundParameters.Keys) -or ('RedirectOutputSuffix' -in $PSBoundParameters.Keys) -and !$SuppressOutput)
        {
            throw 'Cannot redirect output if SuppressOutput is not set'
        }
    }
    
    process
    {
        # Start off by ensuring we can find the command and then get it's full path.
        # This is useful when using things like Set-Alias as the Start-Process command won't have access to these
        # as aliases are not passed through to the child process so instead we can use the full path to the alias
        Write-Verbose "Finding absolute path to command $FilePath"
        try
        {
            $AbsoluteCommandPath = (Get-Command $FilePath -ErrorAction Stop).Definition
        }
        catch
        {
            throw "Could not find command $FilePath.`n$($_.Exception.Message)"
        }
        # Note: the arguments may leak sensitive information so be wary of exposing them
        Write-Debug "Calling '$AbsoluteCommandPath' with arguments: '$($ArgumentList -join ' ')'"
        Write-Debug "Valid exit codes: $($ExitCodes -join ', ')"
        # When we want to suppress output we need to redirect the output to a file
        if ($SuppressOutput)
        {
            # Set redirected output to the repos log directory if it exists, otherwise to temp
            if (!$RedirectOutputPath)
            {
                if ($global:RepoLogDirectory)
                {
                    $RedirectOutputPath = $global:RepoLogDirectory
                }
                else
                {
                    # Determine our temp directory depending on flavour of PowerShell
                    if ($PSVersionTable.PSEdition -eq 'Desktop')
                    {
                        $RedirectOutputPath = $env:TEMP
                    }
                    else
                    {
                        $RedirectOutputPath = (Get-PSDrive Temp).Root
                    }
                }
            }

            # Check the redirect stream path is valid
            try
            {
                $RedirectOutputPathCheck = Get-Item $RedirectOutputPath -Force
            }
            catch
            {
                throw "$RedirectOutputPath does not appear to be a valid directory."
            }

            if (!$RedirectOutputPathCheck.PSIsContainer)
            {
                throw "$RedirectOutputPath must be a directory"
            }
            Write-Verbose "Redirecting output to: $RedirectOutputPath"

            # If we don't have a redirect output prefix then create one
            if (-not $RedirectOutputPrefix)
            {
                # See if the value in $FilePath is a path or just a command name.
                # If it's a path we don't want to use that as a prefix for our redirected output files as it could be stupidly long
                # If it's a command name then we can just straight up use that as our redirect name
                try
                {
                    $isPath = Resolve-Path $FilePath -ErrorAction Stop
                }
                catch
                {
                    $RedirectOutputPrefix = $FilePath
                }

                # We've got a path, do some work to extract just the name of the program from the file path
                if ($isPath)
                {
                    try
                    {
                        $RedirectOutputPrefix = $isPath | Get-Item | Select-Object -ExpandProperty Name -ErrorAction Stop
                    }
                    catch
                    {
                        # Don't throw, we'll still get a valid filename below anyways it'll just be missing a prefix
                        Write-Warning 'Failed to auto-generate RedirectOutputPrefix'
                    }        
                }
            }

            # Define our redirected stream names
            $StdOutFileName = "$($RedirectOutputPrefix)_$(Get-Date -Format yyMMddhhmm)_stdout.$($RedirectOutputSuffix)"
            $StdErrFileName = "$($RedirectOutputPrefix)_$(Get-Date -Format yyMMddhhmm)_stderr.$($RedirectOutputSuffix)"

            # Set the paths
            $StdOutFilePath = Join-Path $RedirectOutputPath -ChildPath $StdOutFileName
            $StdErrFilePath = Join-Path $RedirectOutputPath -ChildPath $StdErrFileName

            # Set the default calling params
            $ProcessParams = @{
                FilePath               = $AbsoluteCommandPath
                RedirectStandardError  = $StdErrFilePath
                RedirectStandardOutput = $StdOutFilePath
                PassThru               = $true
                NoNewWindow            = $true
                Wait                   = $true
            }

            # Add optional params if we have them
            if ($ArgumentList)
            {
                $ProcessParams.Add('ArgumentList', $ArgumentList)
            }
            if ($WorkingDirectory)
            {
                $ProcessParams.Add('WorkingDirectory', $WorkingDirectory)
            }
    
            # Run the process
            try
            {
                $Process = Start-Process @ProcessParams
            }
            catch
            {
                # If we get a failure at this stage we won't have any stderr to grab so just return our exception
                throw $_.Exception.Message
            }

            # Check the exit code is expected, if not grab the contents of stderr (if we can) and return it
            if ($Process.ExitCode -notin $ExitCodes)
            {
                $ErrorContent = Get-Content $StdErrFilePath -Raw -ErrorAction SilentlyContinue
                # Write-Error is preferable to 'throw' as it gives much cleaner output, it also allows more control over how errors are handled
                Write-Error "$FilePath has returned a non-zero exit code: $($Process.ExitCode).`n$ErrorContent" -ErrorAction 'Stop'
            }

            # If we've requested the output from this command then return it along with the paths to our StdOut and StdErr files should we need them
            try
            {
                $OutputContent = Get-Content $StdOutFilePath
            }
            catch
            {
                Write-Error "Unable to get contents of $StdOutFilePath.`n$($_.Exception.Message)" -ErrorAction 'Stop'
            }
        }
        else
        {
            # Open an array to store potential error messages (more on this later)
            $ErrorStream = @()
            $OutputContent = @()
            if ($WorkingDirectory)
            {
                try
                {
                    Push-Location
                    Set-Location $WorkingDirectory
                }
                catch
                {
                    throw "Failed to set working directory to '$WorkingDirectory'.`n$($_.Exception.Message)"
                }
            }
            # When we're not suppressing output then we want to stream output to both stdout/stderr and capture in a variable
            & { & $AbsoluteCommandPath $ArgumentList } 2>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord])
                {
                    # Some commands will return info/verbose messages to stderr, we don't want to terminate on these so we store the information
                    # so we can use it later on if we need to.
                    $ErrorStream += $_
                    # Try to write it out as verbose output
                    Write-Verbose $_ -ErrorAction 'SilentlyContinue'
                }
                else
                {
                    $OutputContent += $_
                    Write-Host $_ -ErrorAction 'SilentlyContinue'
                }
            } | Tee-Object -Variable 'OutputContent' # Tee the output to a variable
            if ($WorkingDirectory)
            {
                Pop-Location
            }
            if ($LASTEXITCODE -notin $ExitCodes)
            {
                Write-Error "Command $FilePath exited with code $LASTEXITCODE.`n$ErrorStream" -ErrorAction 'Stop'
            }
        }
    }
    
    end
    {
        if ($PassThru)
        {
            $Return = @{}
            if ($OutputContent)
            {
                $Return.Add('OutputContent', $OutputContent)
            }
            else
            {
                $Return.Add('OutputContent', $null)
            }
            if ($StdOutFilePath)
            {
                $Return.Add('StdOutFilePath', $StdOutFilePath)
            }
            if ($StdErrFilePath)
            {
                $Return.Add('StdErrFilePath', $StdErrFilePath)
            }
            if ($Return.GetEnumerator().Count -gt 0)
            {
                Return $Return
            }
            else
            {
                Return $null
            }
        }
    }
}