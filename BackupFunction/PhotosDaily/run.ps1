param($Timer)

Import-Module rclone.psm1

Write-Host "Starting daily photos backup."
Invoke-Rclone -ShouldDownloadRclone -BackupsToRun syncphotos -RcloneConfigEnvVariableName RCLONE_CONFIG_CONTENTS -Interactive:$false -RCloneCheckers 20 -RCloneTransfers 20