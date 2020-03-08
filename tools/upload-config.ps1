param(
    [string] $ResourceGroup,
    [string] $AppName,
    [string] $ConfigFile,
    [string] $VariableName = "RCLONE_CONFIG_CONTENTS"
)

$ErrorActionPreference = "Stop"

$cfg = Get-Content $ConfigFile
$cfgString = [system.String]::Join("\n", $cfg)

az functionapp config appsettings set -g $ResourceGroup -n $AppName --settings "$VariableName=$CfgString"