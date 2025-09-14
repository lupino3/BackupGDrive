# BackupGDrive

Azure Functions and utilities to synchronize Google Drive to Azure Storage using rclone. This repository contains PowerShell-based Azure Functions and helper utilities for personal backups.

This project is organized to make it easy to run scheduled backups, develop locally, and inspect or modify the rclone configuration securely.

- Components
  - `BackupFunction/` — Azure Functions (PowerShell) that run scheduled jobs to copy Google Drive content into Azure Storage containers. There are sub-folders for different schedules (e.g., `PhotosDaily`, `DocumentsHourly`).
  - `tools/` — Helper scripts used during development and deployment (PowerShell helpers).
  - `template/` and `monitoring/` — ARM/Bicep/template files and monitoring/dashboard resources.

Quick start

1. Read the setup steps in `docs/SETUP.md` to install prerequisites (Azure CLI, rclone) and to configure the Azure Functions locally.
2. See `docs/USAGE.md` for how to run the functions locally and upload rclone configuration securely.
3. Use `tools/upload-config.ps1` to encode and upload the rclone config to the Function App settings (see `docs/SETUP.md`).

Documentation

Detailed documentation has been moved into the `docs/` folder. Start here:

- `docs/SETUP.md` — environment setup and how to configure Azure resources and rclone.
- `docs/USAGE.md` — how to run the functions and upload rclone config.
- `docs/ARCHITECTURE.md` — high-level architecture and component interactions.
