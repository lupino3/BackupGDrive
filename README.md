# BackupGDrive

Azure Functions (PowerShell) + rclone to back up Google Drive data into Azure Storage. Single-purpose, minimal, for personal usage.

## Overview

PowerShell timer-triggered Azure Functions execute rclone using a base64-encoded configuration stored in an app setting. Backups land in Azure Blob Storage. Helper scripts automate infrastructure deployment (ARM) and code publication (zip deploy or `func publish`).

## Architecture

1. Timer trigger fires (see each `BackupFunction/*/function.json`).
2. Function decodes `RCLONE_CONFIG_CONTENTS` into a temporary file.
3. rclone sync/copy runs toward target Azure Storage container using connection from `AzureWebJobsStorage`.
4. Logs go to Application Insights.

Design notes:

- No rclone config committed; all credentials encapsulated in one encoded app setting.
- Managed dependency can load Az module (see `requirements.psd1`).
- Extension bundle `[4.*,5.0.0)` / PowerShell worker runtime 7.4.

## Prerequisites

- PowerShell 7.4
- Azure CLI
- Azure Functions Core Tools (for local run or `func publish`)
- rclone (latest stable)  
- An Azure subscription & permissions to create Storage + Function App

## Setup & Local Run

```powershell
# Clone
git clone https://github.com/lupino3/BackupGDrive
cd BackupGDrive

# Start storage emulator (if using Azurite locally) then:
func host start --csharp --prefix .\BackupFunction # or simply from inside BackupFunction folder: func host start
```

Local settings (`BackupFunction/local.settings.json`) already contains worker/runtime entries. For local testing set an environment variable `RCLONE_CONFIG_CONTENTS` (see next section) or use `upload-config.ps1 -Local $true` and export.

## Rclone Configuration Handling

Store rclone config securely in Azure (app setting) rather than file. Steps:

```powershell
# Preview encoded value (does NOT upload)
pwsh ./tools/upload-config.ps1 -ConfigFile ~/.config/rclone/rclone.conf -Local $true

# Upload to Function App
pwsh ./tools/upload-config.ps1 -ConfigFile ~/.config/rclone/rclone.conf -ResourceGroup <rg> -AppName <functionAppName> -Local $false
```

The script base64-encodes file contents (Unicode) -> sets/prints `RCLONE_CONFIG_CONTENTS`.

## Deployment (Infrastructure & Code)

ARM templates live in `/template`.

Validate / what-if only:

```powershell
pwsh ./tools/deploy.ps1
```

Infrastructure + code (zip deploy):

```powershell
pwsh ./tools/deploy.ps1 -Deploy -FunctionAppName <FunctionAppName>
```

After deployment ALWAYS upload (or update) the rclone config if the app setting is missing or changed (see previous section).

Flags:

- `-SkipValidate` skip template validation
- `-Mode Complete` destructive reconciliation
- `-UseFuncPublish` use Functions Core Tools instead of zip deploy
- `-SkipZipDeploy` infra only
- Custom path: `-FunctionCodePath <path>`; custom artifact name: `-ZipOutput <file>`

## Upgrading Runtime

Already targeting Functions extension `~4` + PowerShell 7.4. To move later:

1. Update `local.settings.json` & `host.json` bundle if required.
2. Adjust `requirements.psd1` Az module version (`10.*` wildcard suggested).
3. Redeploy infra & republish code.

## Scheduling & Logs

- Timer schedules: each `BackupFunction/<FunctionName>/function.json` (`schedule` CRON expression).
- Logs: Stream via portal or CLI:

```powershell
az functionapp log tail -g <rg> -n <FunctionAppName>
```

- Application Insights: instrumentation key / connection string injected via app settings.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Function can't find rclone config | Missing/incorrect `RCLONE_CONFIG_CONTENTS` | Re-run upload script, verify base64 content |
| 403 / auth errors in rclone | Expired/invalid credentials in rclone.conf | Refresh rclone remote and re-upload |

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `tools/deploy.ps1` | What-if + infra deploy (+ optional code zip deploy) |
| `tools/validate-deployment.ps1` | Validate + what-if only |
| `tools/deploy-deployment.ps1` | Alternate combined infra deploy script |
| `tools/upload-config.ps1` | Encode & upload rclone config to app setting |

## Minimal Flow Recap

```powershell
pwsh ./tools/deploy.ps1 -Deploy -FunctionAppName BackupService
pwsh ./tools/upload-config.ps1 -ConfigFile ~/.config/rclone/rclone.conf -ResourceGroup backup -AppName BackupService -Local $false
```
