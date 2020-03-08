# Script currently used for manual backups. Assumes that rclone is installed and configured.

# Docs to back up that live on GDrive.
Write-Host "Documents to back up from GDrive to Azure"
rclone sync 'GDrive:Important Documents' Azure:importantdocuments -P

# Photos: first local disk to GDrive (copy only, since GDrive has more photos).
Write-Host "Photos from local disk to GDrive"
rclone copy d:\Photos 'GDrive:Photos' -P 

# Photos: then sync GDrive to Azure.
Write-Host "Photos from GDrive to Azure"
 rclone sync 'GDrive:Photos' 'Azure:photos' -P --checkers=20 --transfers=20
