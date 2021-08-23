[CmdletBinding()]
param(
    [Parameter(HelpMessage="Set to true to back up photos, false will back up documents only.")]
    [switch]$BackupPhotos = $false,

    [Parameter(HelpMessage="Path to the rclone binary (including the file name). E.g.: 'c:\rclone.exe'.")]
    [ValidateNotNullOrEmpty()]
    [string] $RclonePath = "$PSScriptRoot\rclone.exe",

    [Parameter(HelpMessage="Path to the rclone config file")]
    [ValidateNotNullOrEmpty()]
    [string] $RcloneConfig = "$env:APPDATA\rclone\rclone.conf",

    [Parameter(HelpMessage="Set to true if rclone should be downloaded if missing")]
    [switch]
    $ShouldDownloadRclone = $false,

    # Rclone options.
    [int]$RcloneCheckers = 5,
    [int]$RcloneTransfers = 5
)
$ErrorActionPreference = "stop"
$backups = @(
    [pscustomobject]@{Action="sync"; Source="GDrive:Important Documents"; Destination="Azure:importantdocuments"; Category="documents"},
    [PSCustomObject]@{Action="sync"; Source="GDrive:Important Documents"; Destination="d:\Important Documents"; Category="documents"},
    # Copy from d:\Photos to cloud storage because there are more photos online than locally.
    [PSCustomObject]@{Action="copy"; Source="d:\Photos"; Destination="GDrive:Photos"; Category="photos"},
    [PSCustomObject]@{Action="sync"; Source="GDrive:Photos"; Destination="Azure:Photos"; Category="photos"}
)

# Validation and setup.
if (-not (Test-Path $RCloneConfig)) {
    Write-Error "Could not find the RClone config at $RCloneConfig"
    exit
}
if (-not (Test-Path $RClonePath)) {
    if (-not $ShouldDownloadRclone) {
        Write-Error "Could not find the RClone binary at $RClonePath"
        exit
    }
    $RcloneUri = "https://downloads.rclone.org/rclone-current-windows-amd64.zip" 
    Write-Output "Could not find the RClone binary at $RClonePath. Downloading it as requested, from $RcloneUri"
    Invoke-WebRequest -Uri $RcloneUri -OutFile $env:TMP\rclone.zip
    Expand-Archive -Force $env:TMP\rclone.zip -DestinationPath $env:TMP
    $RclonePath = Get-ChildItem -Path $env:TMP\rclone-v*-windows-amd64\rclone.exe
    Write-Debug "Overriding Rclone path to $RclonePath"
}

# Common rclone parameters.
$rcloneParams = "-P --checkers=$RcloneCheckers --transfers=$RcloneTransfers --config=$RcloneConfig"

# TODO: get the necessary remotes from Source/Destination.
$necessaryRemotes = @("Azure:", "GDrive:")
$remotes = Invoke-Expression "$RClonePath listremotes $rcloneParams"
$ok = $true
$necessaryRemotes | % {
    if (-not ($remotes -contains $_)) {
        Write-Error "Could not find remote $_" -EA:Continue
        $ok = $false
    }
}
if (-not $ok) {
    exit
}

# Future categories support might be more advanced, for now let's just allow
# to skip backing up photos.
$categories = @("documents")
if ($BackupPhotos) {
    $categories = @("documents";"photos")
}

$backups | ForEach-Object {
    if (-not ($categories -icontains $_.Category)) {
        Write-Host "Skipping $($_.Source) → $($_.Destination) as it's in category $($_.Category)"
        return
    }
    $msg = "$($_.Action) $($_.Category): $($_.Source) → $($_.Destination)"
    $spacer = "-" * ($msg.Length)

    Write-Host "$spacer`n$msg`n$spacer"

    $cmd = "$RClonePath $($_.Action) '$($_.Source)' '$($_.Destination)' $rcloneParams"
    Write-Host $cmd
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "There was an error (code $LASTEXITCODE) when doing the transfer. Check the rclone log for more info."
    }
}