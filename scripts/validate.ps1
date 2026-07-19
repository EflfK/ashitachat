$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root "ashitachat\ashitachat.lua"
$config = Join-Path $root "ashitachat\ashitachat_config.lua"
$readme = Join-Path $root "README.md"
$install = Join-Path $root "install.ps1"

foreach ($path in @($addon, $config, $readme, $install)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

$lua = Get-Content -LiteralPath $addon -Raw
$configLua = Get-Content -LiteralPath $config -Raw

$required = @(
    "addon.name = 'ashitachat'",
    "require('common')",
    "require('imgui')",
    "local DEFAULT_TABS =",
    "load_config()",
    "ashitachat_config",
    "state.tabs",
    "local MODE_COLORS =",
    "message_matches_tab(message, tab)",
    "chat_display_mode(e)",
    "selected_tab = 'general'",
    "search_buffer = T{ '' }",
    "config_visible = T{ false }",
    "messages = {}",
    "append_message(e)",
    "message_color(display_mode, category)",
    "render_config_window()",
    "save_config()",
    "config_file_path()",
    "if (is_injected(e)) then",
    "render_chat_window()",
    "ashita.events.register('command'",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('text_in'",
    "ashita.memory.find('FFXiMain.dll'",
    "ashita.memory.write_uint32",
    "/ashitachat config",
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

$requiredConfig = @(
    "tabs = {",
    "filters = { 'all' }",
    "filters = { 'combat' }",
    "filters = { 'group' }",
    "filters = { 'lfg' }",
    "modes =",
    "contains ="
)

foreach ($needle in $requiredConfig) {
    if (-not $configLua.Contains($needle)) {
        throw "Expected pattern not found in config: $needle"
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
