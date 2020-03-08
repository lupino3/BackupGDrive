param(
    [string] $ResourceGroup,
    [string] $AppName,
    [string] $ConfigFile,
    [string] $VariableName = "RCLONE_CONFIG_CONTENTS",
    [bool] $Local=$true
)

$ErrorActionPreference = "Stop"

$cfg = Get-Content $ConfigFile -Raw
$cfgString = [System.Text.Encoding]::Unicode.GetBytes($cfg)
$cfgString = [Convert]::ToBase64String($cfgString)

if ($Local) 
{
    Write-Host "`"$VariableName`": `"$cfgString`""
} 
else 
{
    az functionapp config appsettings set -g $ResourceGroup -n $AppName --settings "$VariableName=$CfgString"
}