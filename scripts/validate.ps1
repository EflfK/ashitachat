$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root "ashitachat\ashitachat.lua"
$readme = Join-Path $root "README.md"
$install = Join-Path $root "install.ps1"

foreach ($path in @($addon, $readme, $install)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

$lua = Get-Content -LiteralPath $addon -Raw

$required = @(
    "addon.name = 'ashitachat'",
    "require('common')",
    "require('imgui')",
    "local TABS =",
    "selected_tab = 'general'",
    "search_buffer = T{ '' }",
    "messages = {}",
    "append_message(e)",
    "render_chat_window()",
    "ashita.events.register('command'",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('text_in'",
    "ashita.memory.find('FFXiMain.dll'",
    "ashita.memory.write_uint32",
    "e.injected == true",
    "is_ashitachat_message(e.message)",
    "not is_injected(e)",
    "e.blocked = true"
)

foreach ($needle in $required) {
    if (-not $lua.Contains($needle)) {
        throw "Expected pattern not found in addon: $needle"
    }
}

$forbidden = @(
    "QueueCommand",
    "AddOutgoingPacket",
    "AddIncomingPacket",
    "packet_in",
    "packet_out",
    "/ma ",
    "/ja ",
    "/item ",
    "/target ",
    "/attack "
)

foreach ($needle in $forbidden) {
    if ($lua.Contains($needle)) {
        throw "Forbidden active-helper surface found in addon: $needle"
    }
}

Write-Host "AshitaChat validation passed."
