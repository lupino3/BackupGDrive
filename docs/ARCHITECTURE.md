# Architecture

High level overview

- Timer-triggered PowerShell Azure Functions decode a stored rclone configuration and execute rclone commands to copy files from Google Drive to Azure Storage containers.
- The rclone configuration is stored in an app setting as a base64-encoded Unicode string (`RCLONE_CONFIG_CONTENTS`).

Component interactions

1. Azure Function (PowerShell) starts on schedule.
2. The function decodes `RCLONE_CONFIG_CONTENTS` into a temporary rclone config file.
3. rclone runs (via the included scripts/modules) and writes data into Azure Blob Storage.
4. Function logs and application insights capture status.

Notes

- This setup avoids storing credentials in files in the repository. Keep any secrets in Azure Key Vault or Function App settings.
