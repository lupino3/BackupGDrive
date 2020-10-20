# Script currently used for manual backups. Assumes that rclone is installed and configured.

# Docs to back up that live on GDrive.
Write-Host "-----------------------------------------"
Write-Host "Documents to back up from GDrive to Azure"
Write-Host "-----------------------------------------"
rclone sync 'GDrive:Important Documents' Azure:importantdocuments -P

Write-Host "----------------------------------------------"
Write-Host "Documents to back up from GDrive to Local Disk"
Write-Host "----------------------------------------------"
rclone sync 'GDrive:Important Documents' "d:\Important Documents" -P

# Photos: first local disk to GDrive (copy only, since GDrive has more photos).
Write-Host "--------------------------------"
Write-Host "Photos from local disk to GDrive"
Write-Host "--------------------------------"
rclone copy d:\Photos 'GDrive:Photos' -P 

# Photos: then sync GDrive to Azure.
Write-Host "---------------------------"
Write-Host "Photos from GDrive to Azure"
Write-Host "---------------------------"
rclone sync 'GDrive:Photos' 'Azure:photos' -P --checkers=20 --transfers=20

# Old HD Backup local -> GDrive
Write-Host "-----------------------------------"
Write-Host "HD Backup from local disk to GDrive"
Write-Host "-----------------------------------"
rclone sync "d:\HD Backup" 'GDrive:HD Backup' -P --checkers=20 --transfers=20

# Old HD Backup GDrive -> Azure
Write-Host "------------------------------"
Write-Host "HD Backup from GDrive to Azure"
Write-Host "------------------------------"
rclone sync 'GDrive:HD Backup' Azure:hdbackup -P --checkers=20 --transfers=20
