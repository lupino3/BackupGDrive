using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "BackupGDrive Function Invoked."

# TODO: remove global variables and make Get-Rclone and 
# Get-RcloneConfigFile take proper parameters.
$RCLONE_CMD = "$PSScriptRoot\rclone.exe"
$RCLONE_CONFIG_FILE = "$PSScriptRoot\rclone.cfg"

function Get-RcloneConfigFile() {
    if ([string]::IsNullOrWhiteSpace($Env:RCLONE_CONFIG)) {
        Write-Host "The RCLONE_CONFIG environment variable, which should contain the rclone config, is empty."
        return $false
    }

    $Env:RCLONE_CONFIG.Replace("\n", "`r`n") | Out-File $RCLONE_CONFIG_FILE
    return $true
}

function Get-Rclone() {
    # Download rclone, if it's not there already.
    if (Test-Path -Path $RCLONE_CMD) {
        Write-Host "rclone.exe found"
        return $true
    } 

    Write-Host "rclone not present; downloading"
    $rcloneArchive = "$Env:TEMP\rclone.zip"

    # TODO: download from Azure blob instead of rclone.org.
    Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $rcloneArchive
    $files = Expand-Archive -Path $rcloneArchive -DestinationPath $Env:TEMP -Force -PassThru
    Write-Host "Extracted $($files.Count) files: $files"

    $rcloneExe = $files | Where-Object {$_.Extension -ieq ".exe"}
    Write-Host "Executable: $rcloneExe"

    Copy-Item $rcloneExe $RCLONE_CMD

    if (-not (Test-Path -path $RCLONE_CMD)) {
        return $false
    }
    return $true
}

if (-not (Get-Rclone)) {
    $body = "Couldn't download rclone, exiting."
    Write-Host $body

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::ServiceUnavailable
        Body = $body
    })
}

# Copy the configuration from the environment variable RCLONE_CONFIG to the file $RCLONE_CONFIG_FILE.
# The config file is still not used by rclone.
Get-RcloneConfigFile

$body = Invoke-Expression "$RCLONE_CMD config file"

# Associate values to output bindings by calling 'Push-OutputBinding'.

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})