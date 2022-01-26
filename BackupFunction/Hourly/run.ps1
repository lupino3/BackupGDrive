param($Timer)

Import-Module rclone.psm1

Write-Host "Starting Invoke-Rclone."

Invoke-Rclone -ShouldDownloadRclone -BackupsToRun syncdocs -RcloneConfigEnvVariableName RCLONE_CONFIG_CONTENTS -Interactive:$false
