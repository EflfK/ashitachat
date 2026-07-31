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
    "progress = true",
    "return 'progress'",
    "local FISHING_MESSAGE_PATTERNS =",
    "local function is_fishing_message(lower)",
    "is_fishing_message(lower)",
    "key == 'general' or key == 'default'",
    "something caught the hook!+",
    "enough skill to reel this one in",
    "keen angler's senses tell you",
    "this strength%.%.%. epic catch",
    "your skill level is too low to catch",
    "you lost your catch",
    "your line breaks",
    "you give up and reel in your line",
    "the paper on your scoop ripped",
    "goldfish approaches",
    "the goldfish slipped off your scoop",
    "fishes up .+[%.!]$",
    "caught .+[%.!]$",
    "fishing skill reaches level %d+%.$",
    "skill rises %d+%.?%d* points?%.$",
    "local NATIVE_DIALOG_MODES =",
    "{ key = 'npc', label = 'NPC', modes = { 150, 151, 152 } }",
    "message_matches_tab(message, tab)",
    "tell_peer_from_message(mode, text)",
    "text:match('^%s*([A-Za-z][A-Za-z0-9_-]*)>>')",
    "text:match('^%s*>>%s*([A-Za-z][A-Za-z0-9_-]*)%s*:')",
    "open_tell_tab(tell_peer)",
    "close_tell_tab(window, close_key)",
    "tab.dynamic_tell = true",
    "tab.tell_peer = peer_key",
    "message.tell_peer == tab.tell_peer",
    "elseif (has_tell_tabs(window))",
    "chat_display_mode(e)",
    "selected_tab = normalize_key",
    "search_buffer = T{ '' }",
    "config_visible = T{ false }",
    "config_windows = {}",
    "messages = {}",
    "HISTORY_VERSION = 2",
    "HISTORY_MESSAGE_LIMIT = 100",
    "ashitachat_history.lua",
    "local function save_history()",
    "local function load_history()",
    "append_message(e)",
    "message_matches_window(message, window)",
    "mark_matching_windows_scroll_to_bottom(message)",
    "message_color(display_mode, category)",
    "ParseAutoTranslate(text, true)",
    "if (NATIVE_DIALOG_MODES[mode] ~= true)",
    "text:strip_colors():strip_translate(true)",
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
    "toggle_native",
    "load_config();`n    local restored_count, history_error = load_history();`n    set_hidden(true);",
    "set_hidden(not state.hide_native)",
    "ashita.events.register('command'",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('text_in'",
    "/ashitachat config",
    "Mode IDs##ashitachat_config_window_%d_tab_%d_modes",
    "e.injected == true",
    "if (mode == 190 or display_mode == 190) then",
    "if (mode == 190) then",
    "state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1",
    "is_ashitachat_message(e.message)",
    "not is_injected(e)",
    "NATIVE_DIALOG_MODES[mode] == true",
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
    "filters = { 'progress' }",
    "modes = { 1, 4, 5, 8, 9, 12, 13, 150, 151, 152, 210, 220, 222 }",
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
    "ashita.memory.find",
    "ashita.memory.write",
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
