param(
    [string]$AshitaRoot = "C:\Games\CatsEyeXI\catseyexi-client\Ashita",
    [switch]$Force,
    [switch]$SkipAutoload
)

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "ashitachat"
$target = Join-Path $AshitaRoot "addons\ashitachat"
$startupScript = Join-Path $AshitaRoot "scripts\default.txt"
$startupLoadLine = "/addon load ashitachat"
$startupHideLine = "/ashitachat hide"
$backupRoot = Join-Path $PSScriptRoot ".local-backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $backupRoot $timestamp
$startupBackup = $null
$autoloadStatus = "skipped"

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

function Find-StartupLineIndex {
    param(
        [Parameter(Mandatory)][string[]]$Lines,
        [Parameter(Mandatory)][string]$Needle
    )

    $needleLower = $Needle.ToLowerInvariant()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim().ToLowerInvariant() -eq $needleLower) {
            return $index
        }
    }

    return -1
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

if (-not $SkipAutoload) {
    if (Test-Path -LiteralPath $startupScript) {
        $startupLines = @(Get-Content -LiteralPath $startupScript)
        $loadIndex = Find-StartupLineIndex -Lines $startupLines -Needle $startupLoadLine
        $hideIndex = Find-StartupLineIndex -Lines $startupLines -Needle $startupHideLine
        $hideAfterLoad = ($loadIndex -ge 0 -and $hideIndex -gt $loadIndex)

        if ($loadIndex -ge 0 -and $hideAfterLoad) {
            $autoloadStatus = "startup commands already present in: $startupScript"
        } else {
            if (-not (Test-Path -LiteralPath $backup)) {
                New-Item -ItemType Directory -Force -Path $backup | Out-Null
            }

            $startupBackup = Join-Path $backup "default.txt"
            Copy-Item -LiteralPath $startupScript -Destination $startupBackup -Force

            $added = @()
            if ($loadIndex -lt 0) {
                Add-Content -LiteralPath $startupScript -Value $startupLoadLine
                $added += $startupLoadLine
            }
            if (-not $hideAfterLoad) {
                Add-Content -LiteralPath $startupScript -Value $startupHideLine
                $added += $startupHideLine
            }

            $autoloadStatus = "added/updated in: $startupScript ($($added -join ', '))"
        }
    } else {
        $autoloadStatus = "not added; startup script not found: $startupScript"
    }
}

$startupBackupForRollback = ""
if ($startupBackup -ne $null) {
    $startupBackupForRollback = $startupBackup
}

$rollback = Join-Path $backupRoot "rollback-$timestamp.ps1"
$rollbackContent = @"
`$ErrorActionPreference = "Stop"
`$target = "$target"
`$backupAddon = "$(Join-Path $backup "ashitachat")"
`$startupScript = "$startupScript"
`$startupBackup = "$startupBackupForRollback"

if (Test-Path -LiteralPath `$target) {
    Remove-Item -LiteralPath `$target -Recurse -Force
}

if (Test-Path -LiteralPath `$backupAddon) {
    Copy-Item -LiteralPath `$backupAddon -Destination `$target -Recurse -Force
    Write-Host "Restored previous ashitachat addon."
} else {
    Write-Host "Removed ashitachat addon. No previous addon backup was present."
}

if (`$startupBackup -ne "" -and (Test-Path -LiteralPath `$startupBackup)) {
    Copy-Item -LiteralPath `$startupBackup -Destination `$startupScript -Force
    Write-Host "Restored previous Ashita startup script."
}
"@

New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
Set-Content -LiteralPath $rollback -Value $rollbackContent -Encoding UTF8

Write-Host "Installed ashitachat addon to: $target"
Write-Host "Autoload: $autoloadStatus"
Write-Host "Load now in game with: /addon load ashitachat"
Write-Host "Hide native chat with: /ashitachat hide"
Write-Host "Rollback script: $rollback"
