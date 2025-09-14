import-module $PSScriptRoot\..\BackupFunction\Modules\rclone\rclone.psm1

Get-Date *>> C:\users\andre\Desktop\backup.log
$ProgressPreference = 'SilentlyContinue'    # Inhibit output from Invoke-WebRequest
Invoke-Rclone -RclonePath c:\users\andre\rclone.exe -ShouldDownloadRclone -BackupsToRun syncdocs -RCloneConfigSearchPath c:\users\andre\.config\rclone *>> C:\users\andre\Desktop\backup.log
$ProgressPreference = 'Continue'            # Resume progress output
Get-Date *>> C:\users\andre\Desktop\backup.log