param(
    [string]$AshitaRoot = "C:\Games\CatsEyeXI\catseyexi-client\Ashita",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "ashitachat"
$target = Join-Path $AshitaRoot "addons\ashitachat"
$backupRoot = Join-Path $PSScriptRoot ".local-backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $backupRoot $timestamp

function Save-ConfigMigration {
    param(
        [Parameter(Mandatory)][string]$InstalledAddonPath,
        [Parameter(Mandatory)][string]$AshitaRoot
    )

    $legacyConfig = Join-Path $InstalledAddonPath "ashitachat_config.lua"
    if (-not (Test-Path -LiteralPath $legacyConfig)) {
        return
    }

    $configRoot = Join-Path $AshitaRoot "config\addons\ashitachat"
    $runtimeConfig = Join-Path $configRoot "ashitachat_config.lua"
    if (Test-Path -LiteralPath $runtimeConfig) {
        return
    }

    New-Item -ItemType Directory -Force -Path $configRoot | Out-Null
    Copy-Item -LiteralPath $legacyConfig -Destination $runtimeConfig -Force
    Write-Host "Migrated ashitachat config to: $runtimeConfig"
}

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source addon folder does not exist: $source"
}

if (-not (Test-Path -LiteralPath $AshitaRoot)) {
    throw "Ashita root does not exist: $AshitaRoot"
}

if (Test-Path -LiteralPath $target) {
    Save-ConfigMigration -InstalledAddonPath $target -AshitaRoot $AshitaRoot

    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    Copy-Item -LiteralPath $target -Destination (Join-Path $backup "ashitachat") -Recurse -Force

    if (-not $Force) {
        Write-Host "Existing addon backed up to: $backup"
    }
}

if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $target -Recurse -Force

$rollback = Join-Path $backupRoot "rollback-$timestamp.ps1"
$rollbackContent = @"
`$ErrorActionPreference = "Stop"
`$target = "$target"
`$backupAddon = "$(Join-Path $backup "ashitachat")"

if (Test-Path -LiteralPath `$target) {
    Remove-Item -LiteralPath `$target -Recurse -Force
}

if (Test-Path -LiteralPath `$backupAddon) {
    Copy-Item -LiteralPath `$backupAddon -Destination `$target -Recurse -Force
    Write-Host "Restored previous ashitachat addon."
} else {
    Write-Host "Removed ashitachat addon. No previous addon backup was present."
}
"@

New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
Set-Content -LiteralPath $rollback -Value $rollbackContent -Encoding UTF8

Write-Host "Installed ashitachat addon to: $target"
Write-Host "Load in game with: /addon load ashitachat"
Write-Host "Rollback script: $rollback"
