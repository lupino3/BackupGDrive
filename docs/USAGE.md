# Usage

This document explains how to run the various components in this repository.

Running Azure Functions locally

1. Ensure [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-powershell) are installed and the PowerShell runtime is available.
2. From the `BackupFunction/` folder run the function host (for example using `func host start`).
3. Ensure the environment variables described in `docs/SETUP.md` are available (e.g., `RCLONE_CONFIG_CONTENTS`).

Uploading rclone config

- Use `tools/upload-config.ps1` to base64-encode a local `rclone.conf`. For local testing, set the environment variable `RCLONE_CONFIG_CONTENTS` to the output value. To upload to Azure Function App settings, use the Azure CLI as shown in `docs/SETUP.md`.

Scheduling and triggers

- The timer schedules for each function are defined in `BackupFunction/*/function.json` files. Modify there to change frequency.

Debugging

- Check function logs locally via the function host. In Azure, use Application Insights or the function's streaming logs to inspect runs.