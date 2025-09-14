param(
    [string] $ResourceGroup = "backup",
    [string] $TemplateFile = "template/template.json",
    [string] $ParametersFile = "template/parameters.json",
    [switch] $Deploy,
    [switch] $SkipValidate,
    [ValidateSet('Incremental','Complete')]
    [string] $Mode = 'Incremental',
    [string] $FunctionAppName,              # If provided triggers zip deploy after infra deployment
    [string] $FunctionCodePath = "BackupFunction",
    [string] $ZipOutput = "functionapp.zip",
    [switch] $SkipZipDeploy,
    [switch] $UseFuncPublish                # alternative publish using func core tools
)

$ErrorActionPreference = "Stop"

if ($Deploy) {
    Write-Host "Full deployment mode, changes will be applied." -ForegroundColor Yellow
} else {
    Write-Host "Running what-if only, no deployment will be performed." -ForegroundColor Yellow
}

if (-not (az account show 2>$null)) {
    Write-Host "Logging into Azure..." -ForegroundColor Cyan
    az login | Out-Null
}
Write-Host "Logged in." -ForegroundColor Green

if (-not (az group exists -n $ResourceGroup | ConvertFrom-Json)) {
    Write-Host "Creating resource group '$ResourceGroup'..." -ForegroundColor Yellow
    az group create -n $ResourceGroup -l westeurope | Out-Null
}

if (-not $SkipValidate) {
    Write-Host "Validating template..." -ForegroundColor Cyan
    az deployment group validate -g $ResourceGroup --mode $Mode --template-file $TemplateFile --parameters @$ParametersFile | Out-Null
    Write-Host "Validation passed." -ForegroundColor Green
}

Write-Host "Running what-if ($Mode mode)..." -ForegroundColor Cyan
az deployment group what-if -g $ResourceGroup --mode $Mode --template-file $TemplateFile --parameters @$ParametersFile

if (-not $Deploy) { return }

Write-Host "Deploying infrastructure ($Mode mode)..." -ForegroundColor Cyan
az deployment group create -g $ResourceGroup --mode $Mode --template-file $TemplateFile --parameters @$ParametersFile | Out-Null
Write-Host "Infrastructure deployment complete." -ForegroundColor Green

# Optional function code deployment
if ($FunctionAppName -and -not $SkipZipDeploy) {
    if (-not (Test-Path $FunctionCodePath)) {
        throw "Function code path '$FunctionCodePath' not found."
    }

    if ($UseFuncPublish) {
        Write-Host "Publishing function code with 'func azure functionapp publish'..." -ForegroundColor Cyan
        func azure functionapp publish $FunctionAppName --powershell
    } else {
        Write-Host "Creating zip package '$ZipOutput' from '$FunctionCodePath'..." -ForegroundColor Cyan
        if (Test-Path $ZipOutput) { Remove-Item $ZipOutput -Force }

        # Exclude local.settings.json and any bin/ obj/ artifacts
        $exclude = @('local.settings.json','bin','obj')
        $tempStaging = Join-Path ([IO.Path]::GetTempPath()) ("funcpkg-" + [Guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempStaging | Out-Null

        Get-ChildItem -Path $FunctionCodePath -Recurse | Where-Object {
            $relative = $_.FullName.Substring((Resolve-Path $FunctionCodePath).Path.Length).TrimStart('\\','/')
            -not ($exclude | ForEach-Object { $relative -like "$_*" -or $relative -eq $_ })
        } | ForEach-Object {
            if (-not $_.PSIsContainer) {
                $dest = Join-Path $tempStaging $relative
                New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
                Copy-Item $_.FullName $dest -Force
            }
        }

        Compress-Archive -Path (Join-Path $tempStaging '*') -DestinationPath $ZipOutput -Force
        Write-Host "Zip size: $(([math]::Round((Get-Item $ZipOutput).Length/1kb,2))) KB" -ForegroundColor DarkGray

        Write-Host "Deploying zip to Function App '$FunctionAppName'..." -ForegroundColor Cyan
        az functionapp deployment source config-zip -g $ResourceGroup -n $FunctionAppName --src $ZipOutput | Out-Null
        Write-Host "Zip deploy complete." -ForegroundColor Green

        Remove-Item $tempStaging -Recurse -Force
    }
}
else {
    if ($FunctionAppName) { Write-Host "Skipping zip deploy as requested (SkipZipDeploy)." -ForegroundColor Yellow }
    else { Write-Host "No FunctionAppName specified; skipping function code deployment." -ForegroundColor Yellow }
}

Write-Host "All tasks finished." -ForegroundColor Green

Write-Host "" # spacer
Write-Host "==================== IMPORTANT ====================" -ForegroundColor Red
Write-Host "RCLONE CONFIG NOT DEPLOYED BY THIS SCRIPT." -ForegroundColor Red
Write-Host "If you have not already set the rclone config on the Function App, run:" -ForegroundColor Red
Write-Host "  pwsh ./tools/upload-config.ps1 -ConfigFile <path-to-rclone.conf> -ResourceGroup $ResourceGroup -AppName $FunctionAppName -Local:\$false" -ForegroundColor Yellow
Write-Host "(Use -Local \$true first to preview the encoded value before uploading.)" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Red
