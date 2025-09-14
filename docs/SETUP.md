# Setup

This document describes how to prepare a local development environment and how to configure Azure resources required by the BackupGDrive project.

Prerequisites

- Windows, macOS or Linux
- PowerShell (for function PowerShell scripts)
- Azure CLI (az)
- rclone (https://rclone.org) — tested with recent stable releases

## Local development

1. Clone the repository.
2. Install rclone and test `rclone config` locally.
3. Install Azure Functions Core Tools if you want to run the PowerShell functions locally.

## Configuring rclone configuration

The repository expects rclone config to be stored securely in an Azure Function App setting as a base64-encoded Unicode string. Use `tools/upload-config.ps1` to convert and print the encoded string for local testing or to upload it to Function App settings:

See `docs/USAGE.md` for examples.

## Azure Function app setup

- Create an Azure Storage account and container for backups.
- Create an Azure Function App for PowerShell runtime.
- Add any required app settings (e.g., `RCLONE_CONFIG_CONTENTS`, storage connection strings, container names).

## Security

- Keep rclone config secure (it may contain OAuth tokens or service account credentials).
- Do not commit `rclone.conf` to source control.

## Troubleshooting

- If functions fail to find the rclone configuration, confirm the app setting name and the encoding.
- When testing locally, check that the environment variable is visible to the function host process.