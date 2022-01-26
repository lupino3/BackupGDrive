param($Timer)

Import-Module rclone.psm1

Write-Host "Starting hourly documents backup."
Invoke-Rclone -ShouldDownloadRclone -BackupsToRun syncdocs -RcloneConfigEnvVariableName RCLONE_CONFIG_CONTENTS -Interactive:$false
