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
$installContent = Get-Content -LiteralPath $install -Raw

$required = @(
    "addon.name = 'ashitachat'",
    "require('common')",
    "require('imgui')",
    "local DEFAULT_TABS =",
    "local DEFAULT_WINDOWS =",
    "load_config()",
    "ashitachat_config",
    "state.windows",
    "window_by_key",
    "local MODE_COLORS =",
    "local MODE_FILTERS =",
    "message_matches_tab(message, tab)",
    "chat_display_mode(e)",
    "selected_tab = normalize_key",
    "search_buffer = T{ '' }",
    "config_visible = T{ false }",
    "config_windows = {}",
    "messages = {}",
    "append_message(e)",
    "message_color(display_mode, category)",
    "render_config_window()",
    "render_config_mode_checkbox(row, window_index, tab_index, mode_filter)",
    "path_join(install_path, 'config')",
    "path_join(config_root, 'addons')",
    "window.window_x",
    "window.window_width",
    "window.show_tabs",
    "window.show_search",
    "window.show_footer",
    "window.show_border",
    "window.show_scrollbar",
    "window.background_opacity",
    "track_window_layout(window)",
    "ensure_config_dir()",
    "legacy_config_file_path()",
    "migrate_legacy_config()",
    "load_lua_config_file(path)",
    "save_config()",
    "config_file_path()",
    "if (is_injected(e)) then",
    "render_chat_windows()",
    "ashita.events.register('command'",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('text_in'",
    "ashita.memory.find('FFXiMain.dll'",
    "ashita.memory.write_uint32",
    "/ashitachat config",
    "Mode IDs##ashitachat_config_window_%d_tab_%d_modes",
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
    "windows = {",
    "key = 'main'",
    "window_x = 18",
    "window_y = 528",
    "window_width = 840",
    "window_height = 310",
    "show_tabs = false",
    "show_search = false",
    "show_footer = false",
    "show_border = false",
    "show_scrollbar = false",
    "background_opacity = 0.00",
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

$requiredInstall = @(
    "Save-ConfigMigration",
    "config\addons\ashitachat",
    "ashitachat_config.lua",
    "Migrated ashitachat config to:",
    "SkipAutoload",
    "/addon load ashitachat",
    "/ashitachat hide",
    "Find-StartupLineIndex",
    "startup commands already present",
    "Restored previous Ashita startup script."
)

foreach ($needle in $requiredInstall) {
    if (-not $installContent.Contains($needle)) {
        throw "Expected pattern not found in installer: $needle"
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
