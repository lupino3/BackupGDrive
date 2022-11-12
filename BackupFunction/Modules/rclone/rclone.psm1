function Invoke-Rclone {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(HelpMessage="Path to the rclone binary (including the file name). E.g.: 'c:\rclone.exe'.")]
        [ValidateNotNullOrEmpty()]
        [string] $RclonePath = "$PSScriptRoot\rclone.exe",

        [Parameter(HelpMessage="Paths where to search the rclone config file (rclone.conf)",
                ParameterSetName = "Path")]
        [ValidateNotNullOrEmpty()]
        [string[]] $RCloneConfigSearchPath = @(".", "$env:userprofile\.config\rclone", "$env:APPDATA\rclone"),

        [Parameter(HelpMessage="Environment variable containing a Base64-encoded RClone configuration.",
                ParameterSetName="Env")]
        [ValidateNotNullOrEmpty()]
        [string] $RCloneConfigEnvVariableName,

        [Parameter(HelpMessage="Set to true if rclone should be downloaded if missing")]
        [switch] $ShouldDownloadRclone,

        [Parameter(HelpMessage="List of backup jobs to run. Possible values: syncdocs, localcopydocs, uploadphotos, syncphotos")]
        [string[]] $BackupsToRun = @("syncdocs"),

        [Parameter(HelpMessage="Set to true if the cmdlet is run in an interactive context")]
        [switch] $Interactive,

        # Rclone options.
        [Parameter()] [int]$RcloneCheckers = 5,
        [Parameter()] [int]$RcloneTransfers = 5
    )
    begin {
        $ErrorActionPreference = "stop"

        # TODO: move to config file.
        $backups = @{
            "syncdocs" = [pscustomobject]@{Action="sync"; Source="GDrive:Important Documents"; Destination="Azure:importantdocuments"};
            "localcopydocs" = [PSCustomObject]@{Action="sync"; Source="GDrive:Important Documents"; Destination="f:\Important Documents"};
            "uploadphotos" = [PSCustomObject]@{Action="copy"; Source="f:\Photos"; Destination="GDrive:Photos"}; # Copy from d:\Photos to cloud storage because there are more photos online than locally.
            "syncphotos" = [PSCustomObject]@{Action="sync"; Source="GDrive:Photos"; Destination="Azure:photos"};
        }
        # Validate command line options.
        $invalidBackups = $BackupsToRun | Where-Object {-not $backups.Contains($_)}
        if ($invalidBackups.Count -gt 0) {
            Write-Error "Invalid backup names: $InvalidBackups." 
            exit
        }

        $toRun = $backups.keys | Where-Object {$BackupsToRun -contains $_}
        Write-Debug "Will run $toRun backups."

        $RcloneConfigPath = ""
        if ($RCloneConfigEnvVariableName) {
            $data = [System.Environment]::GetEnvironmentVariable($RCloneConfigEnvVariableName)
            if (-not $data) {
                Write-Error "The environment variable $RcloneConfigEnvVariableName is empty."
                exit
            }
            $tempFile = New-TemporaryFile
            Write-Debug "Created temporary file $tempfile."
            $decodedConfig = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($data))
            Write-Debug "Decoded config."
            $decodedConfig | Out-File -FilePath $tempFile 
            $RcloneConfigPath = $tempFile
        } else {
            $found = $false
            foreach($path in $RCloneConfigSearchPath) {
                $RcloneConfigPath = "$path\rclone.conf"
                Write-Debug "Trying $RcloneConfigPath"
                if (Test-Path $RcloneConfigPath) {
                    $found = $true
                    break
                }
            }

            # Validation and setup
            if (-not $found) {
                Write-Error "Could not find the RClone config in $RCloneConfigSearchpath"
                exit
            }
        }
        Write-Debug "Using RClone config at $RcloneConfigPath"
        if (-not (Test-Path $RClonePath)) {
            if (-not $ShouldDownloadRclone) {
                Write-Error "Could not find the RClone binary at $RClonePath"
                exit
            }
            $RcloneUri = "https://downloads.rclone.org/rclone-current-windows-amd64.zip" 
            # Use a temporary directory for the script inside $env:TMP to download the rclone binary.
            # Create the directory (if it doesn't exist)
            $tmpDir = "$env:TMP\rclone"
            mkdir $tmpDir -ErrorAction SilentlyContinue | Out-Null
            Remove-Item $tmpDir\* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Output "Could not find the RClone binary at $RClonePath. Downloading it as requested, from $RcloneUri"
            Invoke-WebRequest -Uri $RcloneUri -OutFile $tmpDir\rclone.zip
            Expand-Archive -Force $tmpDir\rclone.zip -DestinationPath $tmpDir
            $RclonePath = Get-ChildItem -Path $tmpDir\rclone-v*-windows-amd64\rclone.exe
            Write-Debug "Overriding Rclone path to $RclonePath"
        }

        # Common rclone parameters.
        $rcloneParams = "--checkers=$RcloneCheckers --transfers=$RcloneTransfers --config=$RcloneConfigPath "

        # TODO: get the necessary remotes from Source/Destination.
        $necessaryRemotes = @("Azure:", "GDrive:")
        $remotes = Invoke-Expression "$RClonePath listremotes $rcloneParams"
        $missingRemote = $false
        foreach ($remote in $necessaryRemotes) {
            if (-not ($remotes -contains $remote)) {
                Write-Error "Could not find remote $remote" -EA:Continue
                $missingRemote = $false
            }
        }
        if ($missingRemote) {
            exit
        }
    }
    process {
        foreach ($backupName in $toRun) {
            $backup = $backups[$backupName]
            Write-Debug "Running $backupName"

            $msg = "[$backupName] $($backup.Action) $($backup.Category): $($backup.Source) → $($backup.Destination)"
            $spacer = "-" * ($msg.Length)

            Write-Host "$spacer`n$msg`n$spacer"
            
            if ($Interactive) {
                $rcloneParams += "-P"
            } else {
                $tmpLogFile = New-TemporaryFile
                $rcloneParams += "--use-json-log --stats=5s -v --log-file=$tmpLogFile"
            }

            $cmd = "$RClonePath $($backup.Action) '$($backup.Source)' '$($backup.Destination)' $rcloneParams"
            Write-Host $cmd
            $rcloneExitCode = 0
            if ($PSCmdlet.ShouldProcess($cmd)) {
                Invoke-Expression $cmd
                $rcloneExitCode = $LASTEXITCODE
            }
            if (-not $Interactive) {
                Get-Content $tmpLogFile | Write-Host
                Remove-Item $tmpLogFile
            }
            if ($rcloneExitCode -ne 0) {
                Write-Error "There was an error (code $LASTEXITCODE) when doing the transfer. Check the rclone log for more info."
            }
        }
    }
    end {
        if ($tempFile) {
            Write-Debug "Removing $tempile"
            Remove-Item $tempFile
        }
    }
}

Export-ModuleMember -Function Invoke-Rclone