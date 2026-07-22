addon.name = 'ashitachat';
addon.author = 'EflfK';
addon.version = '0.1.4';
addon.desc = 'Experimental local chat UI replacement trial for Ashita v4.';

require('common');

local chat = require('chat');
local imgui = require('imgui');

local function imgui_const(name)
    return rawget(_G, name) or 0;
end

local IMGUI = {
    col_window_bg = imgui_const('ImGuiCol_WindowBg'),
    col_child_bg = imgui_const('ImGuiCol_ChildBg'),
    col_border = imgui_const('ImGuiCol_Border'),
    col_button = imgui_const('ImGuiCol_Button'),
    col_button_hovered = imgui_const('ImGuiCol_ButtonHovered'),
    col_button_active = imgui_const('ImGuiCol_ButtonActive'),
    col_frame_bg = imgui_const('ImGuiCol_FrameBg'),
    col_frame_bg_hovered = imgui_const('ImGuiCol_FrameBgHovered'),
    col_text = imgui_const('ImGuiCol_Text'),
    style_window_padding = imgui_const('ImGuiStyleVar_WindowPadding'),
    style_window_border_size = imgui_const('ImGuiStyleVar_WindowBorderSize'),
    style_frame_padding = imgui_const('ImGuiStyleVar_FramePadding'),
    cond_first_use = imgui_const('ImGuiCond_FirstUseEver'),
    window_no_collapse = imgui_const('ImGuiWindowFlags_NoCollapse'),
    window_no_title_bar = imgui_const('ImGuiWindowFlags_NoTitleBar'),
    window_always_auto_resize = imgui_const('ImGuiWindowFlags_AlwaysAutoResize'),
    window_no_scrollbar = imgui_const('ImGuiWindowFlags_NoScrollbar'),
};

local COLORS = {
    panel_bg = { 0.000, 0.000, 0.000, 0.74 },
    child_bg = { 0.000, 0.000, 0.000, 0.00 },
    border = { 0.28, 0.28, 0.30, 0.78 },
    tab = { 0.015, 0.015, 0.018, 0.86 },
    tab_hover = { 0.095, 0.095, 0.105, 0.92 },
    tab_active = { 0.165, 0.165, 0.180, 0.98 },
    frame = { 0.000, 0.000, 0.000, 0.58 },
    frame_hover = { 0.070, 0.070, 0.075, 0.78 },
    tab_text = { 0.78, 0.78, 0.82, 1.00 },
    tab_text_active = { 0.98, 0.98, 1.00, 1.00 },
    timestamp = { 0.58, 0.58, 0.62, 1.00 },
    general = { 0.93, 0.93, 0.93, 1.00 },
    say = { 0.93, 0.93, 0.93, 1.00 },
    shout = { 1.00, 0.48, 0.92, 1.00 },
    yell = { 1.00, 0.82, 0.30, 1.00 },
    tell = { 1.00, 0.58, 1.00, 1.00 },
    party = { 0.55, 0.86, 1.00, 1.00 },
    linkshell = { 0.50, 1.00, 0.48, 1.00 },
    linkshell2 = { 0.55, 1.00, 0.78, 1.00 },
    assist = { 0.62, 0.80, 1.00, 1.00 },
    emote = { 0.82, 0.72, 1.00, 1.00 },
    system = { 1.00, 0.92, 0.48, 1.00 },
    combat = { 1.00, 0.72, 0.38, 1.00 },
    group = { 0.55, 0.86, 1.00, 1.00 },
    lfg = { 1.00, 0.92, 0.28, 1.00 },
    status = { 0.62, 0.62, 0.66, 1.00 },
    empty = { 0.50, 0.50, 0.54, 1.00 },
    success = { 0.42, 0.95, 0.55, 1.00 },
    error = { 1.00, 0.36, 0.32, 1.00 },
};

local DEFAULT_TABS = {
    { key = 'general', label = 'General', filters = { 'all' } },
    { key = 'combat', label = 'Combat Log', filters = { 'combat' } },
    { key = 'group', label = 'Group', filters = { 'group' } },
    { key = 'lfg', label = 'LFG', filters = { 'lfg' } },
};

local DEFAULT_WINDOWS = {
    { key = 'main', label = 'Main', visible = true, tabs = DEFAULT_TABS },
};

local DEFAULT_WINDOW_X = 18;
local DEFAULT_WINDOW_Y = 528;
local DEFAULT_WINDOW_WIDTH = 840;
local DEFAULT_WINDOW_HEIGHT = 310;
local DEFAULT_SHOW_TABS = true;
local DEFAULT_SHOW_SEARCH = true;
local DEFAULT_SHOW_FOOTER = true;
local DEFAULT_SHOW_BORDER = true;
local DEFAULT_SHOW_SCROLLBAR = true;
local DEFAULT_BACKGROUND_OPACITY = 0.74;
local WINDOW_POSITION_MIN = -2000;
local WINDOW_POSITION_MAX = 10000;
local WINDOW_SIZE_MIN = 120;
local WINDOW_SIZE_MAX = 4000;
local BACKGROUND_OPACITY_MIN = 0.00;
local BACKGROUND_OPACITY_MAX = 1.00;
local HISTORY_MESSAGE_LIMIT = 100;

local VALID_FILTERS = {
    all = true,
    general = true,
    combat = true,
    group = true,
    lfg = true,
};

local FILTER_ORDER = { 'all', 'general', 'combat', 'group', 'lfg' };

local MODE_FILTERS = {
    { key = 'npc', label = 'NPC', modes = { 150, 151, 152 } },
    { key = 'say', label = 'Say', modes = { 1, 9 } },
    { key = 'shout', label = 'Shout', modes = { 2, 3, 10 } },
    { key = 'yell', label = 'Yell', modes = { 11 } },
    { key = 'tell', label = 'Tell', modes = { 4, 12 } },
    { key = 'party', label = 'Party', modes = { 5, 13, 210 } },
    { key = 'linkshell', label = 'Linkshell', modes = { 6, 14, 205 } },
    { key = 'linkshell2', label = 'Linkshell 2', modes = { 213, 214, 217 } },
    { key = 'emote', label = 'Emote', modes = { 8 } },
    { key = 'system', label = 'System', modes = { 29, 121 } },
    { key = 'unity', label = 'Unity', modes = { 212 } },
    { key = 'assist', label = 'Assist', modes = { 220, 222 } },
};

local NATIVE_DIALOG_MODES = {
    [150] = true,
    [151] = true,
    [152] = true,
};

local MODE_LABELS = {
    [1] = 'say',
    [2] = 'shout',
    [3] = 'shout',
    [4] = 'tell',
    [5] = 'party',
    [6] = 'linkshell',
    [8] = 'emote',
    [10] = 'shout',
    [11] = 'yell',
    [12] = 'tell',
    [13] = 'party',
    [14] = 'linkshell',
    [205] = 'linkshell',
    [210] = 'party',
    [213] = 'linkshell2',
    [214] = 'linkshell2',
    [217] = 'linkshell2',
    [9] = 'say',
    [29] = 'system',
    [121] = 'system',
    [212] = 'unity',
    [220] = 'assist',
    [222] = 'assist',
};

local MODE_COLORS = {
    [1] = COLORS.say,
    [9] = COLORS.say,
    [2] = COLORS.shout,
    [3] = COLORS.shout,
    [10] = COLORS.shout,
    [11] = COLORS.yell,
    [4] = COLORS.tell,
    [12] = COLORS.tell,
    [5] = COLORS.party,
    [13] = COLORS.party,
    [210] = COLORS.party,
    [6] = COLORS.linkshell,
    [14] = COLORS.linkshell,
    [205] = COLORS.linkshell,
    [213] = COLORS.linkshell2,
    [214] = COLORS.linkshell2,
    [217] = COLORS.linkshell2,
    [8] = COLORS.emote,
    [29] = COLORS.system,
    [121] = COLORS.system,
    [212] = COLORS.linkshell2,
    [220] = COLORS.assist,
    [222] = COLORS.assist,
};

local COMBAT_MODES = {};
for _, mode in ipairs({
    20, 21, 22, 23, 24, 25, 26, 27,
    28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43,
    44, 50, 51, 52, 53, 54, 55, 56,
    57, 58, 59, 60, 61, 62, 63, 64,
    65, 66, 67, 68, 69, 80, 100, 101,
    102, 103, 104, 105, 106, 107, 108,
    109, 110, 111, 112, 113, 114, 122,
    129, 131, 162, 163, 164, 165, 166,
    167, 168, 169, 170, 171, 172, 173,
    174, 175, 176, 177, 178, 179, 180,
    181, 182, 183, 184, 185, 186, 187,
    188, 191,
}) do
    COMBAT_MODES[mode] = true;
end

local state = {
    hide_native = false,
    ui_visible = T{ true },
    config_visible = T{ false },
    windows = {},
    window_by_key = {},
    config_error = nil,
    config_windows = {},
    config_selected_window = 1,
    config_dirty = false,
    config_message = nil,
    config_message_color = nil,
    messages = {},
    message_seq = 0,
    max_messages = 5000,
    font_scale = 1.00,
    scroll_to_bottom = true,
    blocked_count = 0,
    mode_counts = {},
};

local set_hidden;

local commands = {
    ['/ashitachat'] = true,
    ['/achat'] = true,
};

local function trim_string(value)
    if (type(value) ~= 'string') then
        return '';
    end

    return value:gsub('^%s+', ''):gsub('%s+$', '');
end

local function buffer_set(buffer, value)
    buffer[1] = value or '';
end

local function normalize_key(value, fallback)
    local key = trim_string(value):lower():gsub('%s+', '-'):gsub('[^a-z0-9_-]', '');
    if (key == '') then
        return fallback;
    end

    return key;
end

local function normalize_filter(value)
    local filter = trim_string(value):lower();
    if (VALID_FILTERS[filter] == true) then
        return filter;
    end

    return nil;
end

local function normalize_filters(tab)
    local source = tab.filters or tab.filter or {};
    local filters = {};

    if (type(source) ~= 'table') then
        source = { source };
    end

    for _, value in ipairs(source) do
        local filter = normalize_filter(value);
        if (filter ~= nil and filters[filter] ~= true) then
            table.insert(filters, filter);
            filters[filter] = true;
        end
    end

    if (#filters == 0 and tab.modes == nil and tab.mode == nil and tab.contains == nil and tab.contain == nil) then
        table.insert(filters, 'all');
        filters.all = true;
    end

    return filters;
end

local function normalize_modes(tab)
    local source = tab.modes or tab.mode or {};
    local modes = {};
    local mode_map = {};

    if (type(source) ~= 'table') then
        source = { source };
    end

    for _, value in ipairs(source) do
        local mode = tonumber(value);
        if (mode ~= nil) then
            mode = bit.band(math.floor(mode), 0x000000FF);
            if (mode_map[mode] ~= true) then
                table.insert(modes, mode);
                mode_map[mode] = true;
            end
        end
    end

    return modes, mode_map;
end

local function normalize_contains(tab)
    local source = tab.contains or tab.contain or {};
    local contains = {};

    if (type(source) ~= 'table') then
        source = { source };
    end

    for _, value in ipairs(source) do
        local needle = trim_string(value):lower();
        if (needle ~= '') then
            table.insert(contains, needle);
        end
    end

    return contains;
end

local function normalize_int(value, fallback, minimum, maximum)
    local number = tonumber(value);
    if (number == nil) then
        number = fallback;
    end

    number = math.floor(number + 0.5);
    if (minimum ~= nil and number < minimum) then
        number = minimum;
    elseif (maximum ~= nil and number > maximum) then
        number = maximum;
    end

    return number;
end

local function normalize_float(value, fallback, minimum, maximum)
    local number = tonumber(value);
    if (number == nil) then
        number = fallback;
    end

    if (minimum ~= nil and number < minimum) then
        number = minimum;
    elseif (maximum ~= nil and number > maximum) then
        number = maximum;
    end

    return number;
end

local function normalize_bool(value, fallback)
    if (value == nil) then
        return fallback;
    end

    if (type(value) == 'boolean') then
        return value;
    end

    local text = trim_string(value):lower();
    if (text == 'true' or text == 'yes' or text == 'on' or text == '1') then
        return true;
    elseif (text == 'false' or text == 'no' or text == 'off' or text == '0') then
        return false;
    end

    return fallback;
end

local function first_config_value(source, keys)
    for _, key in ipairs(keys or {}) do
        if (source[key] ~= nil) then
            return source[key];
        end
    end

    return nil;
end

local function normalize_visibility_option(source, positive_keys, negative_keys, fallback)
    local value = first_config_value(source, positive_keys);
    if (value ~= nil) then
        return normalize_bool(value, fallback);
    end

    value = first_config_value(source, negative_keys);
    if (value ~= nil) then
        return not normalize_bool(value, not fallback);
    end

    return fallback;
end

local function normalize_tab(raw, index, used_keys)
    local tab = type(raw) == 'table' and raw or {};
    local label = trim_string(tab.label or tab.name);
    if (label == '') then
        label = ('Tab %d'):fmt(index);
    end

    local key = normalize_key(tab.key or tab.id or label, ('tab%d'):fmt(index));
    local base_key = key;
    local suffix = 2;
    while (used_keys[key] == true) do
        key = ('%s%d'):fmt(base_key, suffix);
        suffix = suffix + 1;
    end
    used_keys[key] = true;

    local modes, mode_map = normalize_modes(tab);

    return {
        key = key,
        label = label,
        filters = normalize_filters(tab),
        modes = modes,
        mode_map = mode_map,
        contains = normalize_contains(tab),
    };
end

local function normalize_tabs(source)
    local tabs = {};
    local used_keys = {};

    if (type(source) ~= 'table' or #source == 0) then
        source = DEFAULT_TABS;
    end

    for index, tab in ipairs(source) do
        table.insert(tabs, normalize_tab(tab, index, used_keys));
    end

    if (#tabs == 0) then
        for index, tab in ipairs(DEFAULT_TABS) do
            table.insert(tabs, normalize_tab(tab, index, used_keys));
        end
    end

    return tabs;
end

local function normalize_window(raw, index, used_keys)
    local source = type(raw) == 'table' and raw or {};
    local label = trim_string(source.label or source.name);
    if (label == '') then
        label = ('Window %d'):fmt(index);
    end

    local key = normalize_key(source.key or source.id or label, ('window%d'):fmt(index));
    local base_key = key;
    local suffix = 2;
    while (used_keys[key] == true) do
        key = ('%s%d'):fmt(base_key, suffix);
        suffix = suffix + 1;
    end
    used_keys[key] = true;

    local offset = (index - 1) * 28;

    return {
        key = key,
        label = label,
        visible = T{ source.visible ~= false and source.hidden ~= true },
        window_x = normalize_int(source.window_x or source.x, DEFAULT_WINDOW_X + offset, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX),
        window_y = normalize_int(source.window_y or source.y, DEFAULT_WINDOW_Y - offset, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX),
        window_width = normalize_int(source.window_width or source.width, DEFAULT_WINDOW_WIDTH, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX),
        window_height = normalize_int(source.window_height or source.height, DEFAULT_WINDOW_HEIGHT, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX),
        show_tabs = normalize_visibility_option(source, { 'show_tabs', 'tabs_visible' }, { 'hide_tabs', 'tabs_hidden' }, DEFAULT_SHOW_TABS),
        show_search = normalize_visibility_option(source, { 'show_search', 'search_visible' }, { 'hide_search', 'search_hidden' }, DEFAULT_SHOW_SEARCH),
        show_footer = normalize_visibility_option(source, { 'show_footer', 'footer_visible' }, { 'hide_footer', 'footer_hidden' }, DEFAULT_SHOW_FOOTER),
        show_border = normalize_visibility_option(source, { 'show_border', 'border_visible' }, { 'hide_border', 'border_hidden' }, DEFAULT_SHOW_BORDER),
        show_scrollbar = normalize_visibility_option(source, { 'show_scrollbar', 'show_scrollbars', 'scrollbar_visible', 'scrollbars_visible' }, { 'hide_scrollbar', 'hide_scrollbars', 'scrollbar_hidden', 'scrollbars_hidden' }, DEFAULT_SHOW_SCROLLBAR),
        background_opacity = normalize_float(source.background_opacity or source.bg_opacity or source.opacity, DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX),
        tabs = normalize_tabs(source.tabs),
        tab_by_key = {},
        selected_tab = normalize_key(source.selected_tab or source.selected or '', ''),
        search_buffer = T{ '' },
        scroll_to_bottom = true,
    };
end

local function normalize_windows(source)
    local windows = {};
    local used_keys = {};

    if (type(source) ~= 'table' or #source == 0) then
        source = DEFAULT_WINDOWS;
    end

    for index, window in ipairs(source) do
        table.insert(windows, normalize_window(window, index, used_keys));
    end

    if (#windows == 0) then
        for index, window in ipairs(DEFAULT_WINDOWS) do
            table.insert(windows, normalize_window(window, index, used_keys));
        end
    end

    return windows;
end

local function mark_windows_scroll_to_bottom()
    for _, window in ipairs(state.windows) do
        window.scroll_to_bottom = true;
    end
end

local function path_join(left, right)
    left = tostring(left or '');
    right = tostring(right or '');
    if (left == '') then
        return right;
    end

    local last = left:sub(#left);
    if (last == '\\' or last == '/') then
        return left .. right;
    end

    return left .. '\\' .. right;
end

local function ashita_install_path()
    local ok, install_path = pcall(function ()
        return AshitaCore:GetInstallPath();
    end);
    install_path = ok and trim_string(install_path) or '';
    if (install_path == '') then
        return nil;
    end

    return install_path;
end

local function config_dir_path()
    local install_path = ashita_install_path();
    if (install_path == nil) then
        return nil;
    end

    return path_join(path_join(path_join(install_path, 'config'), 'addons'), addon.name);
end

local function legacy_config_file_path()
    local addon_path = trim_string(addon.path);
    if (addon_path ~= '') then
        return path_join(addon_path, 'ashitachat_config.lua');
    end

    local install_path = ashita_install_path();
    if (install_path ~= nil) then
        return path_join(path_join(install_path, 'addons\\ashitachat'), 'ashitachat_config.lua');
    end

    return 'ashitachat_config.lua';
end

local function config_file_path()
    local dir = config_dir_path();
    if (dir ~= nil) then
        return path_join(dir, 'ashitachat_config.lua');
    end

    return legacy_config_file_path();
end

local function history_file_path()
    local dir = config_dir_path();
    if (dir == nil) then
        return nil;
    end

    return path_join(dir, 'ashitachat_history.lua');
end

local function file_exists(path)
    if (path == nil or path == '') then
        return false;
    end

    local file = io.open(path, 'rb');
    if (file == nil) then
        return false;
    end

    file:close();
    return true;
end

local function read_text_file(path)
    local file, error_message = io.open(path, 'rb');
    if (file == nil) then
        return nil, error_message;
    end

    local contents = file:read('*a');
    file:close();
    return contents, nil;
end

local function write_text_file(path, contents)
    local file, error_message = io.open(path, 'wb');
    if (file == nil) then
        return false, error_message;
    end

    local ok, write_error = file:write(contents);
    file:close();
    if (not ok) then
        return false, write_error;
    end

    return true, nil;
end

local function ensure_config_dir()
    local install_path = ashita_install_path();
    if (install_path == nil) then
        return false, 'Ashita install path is unavailable.';
    end

    if (ashita == nil or ashita.fs == nil) then
        return false, 'Ashita filesystem helpers are unavailable.';
    end

    local config_root = path_join(install_path, 'config');
    local addons_config_dir = path_join(config_root, 'addons');
    local dir = path_join(addons_config_dir, addon.name);

    if (not ashita.fs.exists(config_root)) then
        ashita.fs.create_dir(config_root);
    end
    if (not ashita.fs.exists(addons_config_dir)) then
        ashita.fs.create_dir(addons_config_dir);
    end
    if (not ashita.fs.exists(dir)) then
        ashita.fs.create_dir(dir);
    end

    return true, dir;
end

local function load_lua_config_file(path)
    if (not file_exists(path)) then
        return false, nil, ('Config file not found: %s'):fmt(tostring(path));
    end

    local chunk, load_error = loadfile(path);
    if (chunk == nil) then
        return false, nil, load_error;
    end

    local ok, config = pcall(chunk);
    if (not ok) then
        return false, nil, config;
    end

    return true, config, nil;
end

local function config_string(value)
    return ('%q'):fmt(tostring(value or ''));
end

local function list_text(values)
    local output = {};
    if (type(values) == 'table') then
        for _, value in ipairs(values) do
            table.insert(output, tostring(value));
        end
    end
    return table.concat(output, ', ');
end

local function parse_text_list(value)
    local results = {};
    local seen = {};
    for piece in tostring(value or ''):gmatch('[^,]+') do
        local text = trim_string(piece);
        local key = text:lower();
        if (key ~= '' and seen[key] ~= true) then
            table.insert(results, text);
            seen[key] = true;
        end
    end
    return results;
end

local function parse_mode_list(value)
    local results = {};
    local seen = {};
    for _, piece in ipairs(parse_text_list(value)) do
        local mode = tonumber(piece);
        if (mode ~= nil) then
            mode = bit.band(math.floor(mode), 0x000000FF);
            if (seen[mode] ~= true) then
                table.insert(results, mode);
                seen[mode] = true;
            end
        end
    end
    return results;
end

local function mode_map_from_list(modes)
    local mode_map = {};
    for _, value in ipairs(modes or {}) do
        local mode = tonumber(value);
        if (mode ~= nil) then
            mode = bit.band(math.floor(mode), 0x000000FF);
            mode_map[mode] = true;
        end
    end

    return mode_map;
end

local function mode_list_from_map(mode_map)
    local modes = {};
    for mode, enabled in pairs(mode_map or {}) do
        if (enabled == true) then
            table.insert(modes, mode);
        end
    end

    table.sort(modes);
    return modes;
end

local function mode_buffer_from_map(mode_map)
    return list_text(mode_list_from_map(mode_map));
end

local function sync_row_mode_map(row)
    row.mode_map = mode_map_from_list(parse_mode_list(row.modes_buffer and row.modes_buffer[1] or ''));
end

local function mode_group_enabled(row, modes)
    local mode_map = row.mode_map or {};
    for _, mode in ipairs(modes or {}) do
        if (mode_map[mode] ~= true) then
            return false;
        end
    end

    return #(modes or {}) > 0;
end

local function set_mode_group_enabled(row, modes, enabled)
    row.mode_map = row.mode_map or {};
    for _, mode in ipairs(modes or {}) do
        row.mode_map[mode] = enabled == true or nil;
    end

    buffer_set(row.modes_buffer, mode_buffer_from_map(row.mode_map));
end

local function config_list(values, quote_values)
    local pieces = {};
    for _, value in ipairs(values or {}) do
        table.insert(pieces, quote_values and config_string(value) or tostring(value));
    end

    if (#pieces == 0) then
        return '{ }';
    end

    return ('{ %s }'):fmt(table.concat(pieces, ', '));
end

local function editor_from_tab(tab, index)
    local filters = {};
    local modes = tab.modes or {};
    for _, filter in ipairs(FILTER_ORDER) do
        filters[filter] = false;
    end

    for _, filter in ipairs(tab.filters or {}) do
        if (VALID_FILTERS[filter] == true) then
            filters[filter] = true;
        end
    end

    return {
        key_buffer = T{ tab.key or ('tab%d'):fmt(index) },
        label_buffer = T{ tab.label or ('Tab %d'):fmt(index) },
        filters = filters,
        mode_map = mode_map_from_list(modes),
        modes_buffer = T{ list_text(modes) },
        contains_buffer = T{ list_text(tab.contains) },
    };
end

local function config_editor_tab(row, index)
    local label = trim_string(row.label_buffer and row.label_buffer[1] or '');
    if (label == '') then
        label = ('Tab %d'):fmt(index);
    end

    local filters = {};
    for _, filter in ipairs(FILTER_ORDER) do
        if (row.filters[filter] == true) then
            table.insert(filters, filter);
        end
    end

    return {
        key = normalize_key(row.key_buffer and row.key_buffer[1] or '', ('tab%d'):fmt(index)),
        label = label,
        filters = filters,
        modes = parse_mode_list(row.modes_buffer and row.modes_buffer[1] or ''),
        contains = parse_text_list(row.contains_buffer and row.contains_buffer[1] or ''),
    };
end

local function editor_from_window(window, index)
    local visible = true;
    if (type(window.visible) == 'table') then
        visible = window.visible[1] ~= false;
    elseif (window.visible == false or window.hidden == true) then
        visible = false;
    end

    local background_opacity = normalize_float(window.background_opacity, DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX);

    local tabs = {};
    for tab_index, tab in ipairs(window.tabs or DEFAULT_TABS) do
        table.insert(tabs, editor_from_tab(tab, tab_index));
    end

    return {
        key_buffer = T{ window.key or ('window%d'):fmt(index) },
        label_buffer = T{ window.label or ('Window %d'):fmt(index) },
        visible = visible,
        window_x = window.window_x,
        window_y = window.window_y,
        window_width = window.window_width,
        window_height = window.window_height,
        show_tabs = window.show_tabs ~= false,
        show_search = window.show_search ~= false,
        show_footer = window.show_footer ~= false,
        show_border = window.show_border ~= false,
        show_scrollbar = window.show_scrollbar ~= false,
        background_opacity = background_opacity,
        background_opacity_buffer = T{ ('%.2f'):fmt(background_opacity) },
        tabs = tabs,
    };
end

local function sync_config_editor_from_windows(dirty)
    state.config_windows = {};
    for index, window in ipairs(state.windows) do
        table.insert(state.config_windows, editor_from_window(window, index));
    end

    if (#state.config_windows == 0) then
        local used_keys = {};
        table.insert(state.config_windows, editor_from_window(normalize_window(DEFAULT_WINDOWS[1], 1, used_keys), 1));
    end

    state.config_selected_window = math.floor(tonumber(state.config_selected_window) or 1);
    if (state.config_selected_window < 1 or state.config_selected_window > #state.config_windows) then
        state.config_selected_window = 1;
    end

    state.config_dirty = dirty == true;
    state.config_message = nil;
    state.config_message_color = nil;
end

local function config_editor_tabs(window_row)
    local tabs = {};
    for index, row in ipairs(window_row.tabs or {}) do
        table.insert(tabs, config_editor_tab(row, index));
    end

    return tabs;
end

local function config_editor_window(row, index)
    local label = trim_string(row.label_buffer and row.label_buffer[1] or '');
    if (label == '') then
        label = ('Window %d'):fmt(index);
    end

    return {
        key = normalize_key(row.key_buffer and row.key_buffer[1] or '', ('window%d'):fmt(index)),
        label = label,
        visible = row.visible ~= false,
        window_x = row.window_x,
        window_y = row.window_y,
        window_width = row.window_width,
        window_height = row.window_height,
        show_tabs = row.show_tabs ~= false,
        show_search = row.show_search ~= false,
        show_footer = row.show_footer ~= false,
        show_border = row.show_border ~= false,
        show_scrollbar = row.show_scrollbar ~= false,
        background_opacity = normalize_float(row.background_opacity_buffer and row.background_opacity_buffer[1] or row.background_opacity, row.background_opacity or DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX),
        tabs = config_editor_tabs(row),
    };
end

local function config_editor_windows()
    local windows = {};
    for index, row in ipairs(state.config_windows) do
        local key = normalize_key(row.key_buffer and row.key_buffer[1] or '', ('window%d'):fmt(index));
        local runtime = state.window_by_key[key];
        if (runtime ~= nil) then
            row.window_x = runtime.window_x;
            row.window_y = runtime.window_y;
            row.window_width = runtime.window_width;
            row.window_height = runtime.window_height;
        end

        table.insert(windows, config_editor_window(row, index));
    end

    return windows;
end

local function tab_config_fields(tab)
    local fields = {
        ('key = %s'):fmt(config_string(tab.key)),
        ('label = %s'):fmt(config_string(tab.label)),
    };

    if (#(tab.filters or {}) > 0) then
        table.insert(fields, ('filters = %s'):fmt(config_list(tab.filters, true)));
    end
    if (#(tab.modes or {}) > 0) then
        table.insert(fields, ('modes = %s'):fmt(config_list(tab.modes, false)));
    end
    if (#(tab.contains or {}) > 0) then
        table.insert(fields, ('contains = %s'):fmt(config_list(tab.contains, true)));
    end

    return fields;
end

local function window_visible_value(window)
    if (type(window.visible) == 'table') then
        return window.visible[1] ~= false;
    end

    return window.visible ~= false;
end

local function config_text_from_windows(windows)
    local lines = {
        'return {',
        '    windows = {',
    };

    for _, window in ipairs(windows or {}) do
        table.insert(lines, '        {');
        table.insert(lines, ('            key = %s,'):fmt(config_string(window.key)));
        table.insert(lines, ('            label = %s,'):fmt(config_string(window.label)));
        table.insert(lines, ('            visible = %s,'):fmt(window_visible_value(window) and 'true' or 'false'));
        table.insert(lines, ('            window_x = %d,'):fmt(normalize_int(window.window_x, DEFAULT_WINDOW_X, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX)));
        table.insert(lines, ('            window_y = %d,'):fmt(normalize_int(window.window_y, DEFAULT_WINDOW_Y, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX)));
        table.insert(lines, ('            window_width = %d,'):fmt(normalize_int(window.window_width, DEFAULT_WINDOW_WIDTH, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX)));
        table.insert(lines, ('            window_height = %d,'):fmt(normalize_int(window.window_height, DEFAULT_WINDOW_HEIGHT, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX)));
        table.insert(lines, ('            show_tabs = %s,'):fmt(window.show_tabs == true and 'true' or 'false'));
        table.insert(lines, ('            show_search = %s,'):fmt(window.show_search == true and 'true' or 'false'));
        table.insert(lines, ('            show_footer = %s,'):fmt(window.show_footer == true and 'true' or 'false'));
        table.insert(lines, ('            show_border = %s,'):fmt(window.show_border == true and 'true' or 'false'));
        table.insert(lines, ('            show_scrollbar = %s,'):fmt(window.show_scrollbar == true and 'true' or 'false'));
        table.insert(lines, ('            background_opacity = %.2f,'):fmt(normalize_float(window.background_opacity, DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX)));
        table.insert(lines, '            tabs = {');
        for _, tab in ipairs(window.tabs or {}) do
            table.insert(lines, ('                { %s },'):fmt(table.concat(tab_config_fields(tab), ', ')));
        end
        table.insert(lines, '            },');
        table.insert(lines, '        },');
    end

    table.insert(lines, '    },');
    table.insert(lines, '};');
    table.insert(lines, '');

    return table.concat(lines, '\n');
end

local rebuild_window_lookups;

local function apply_config_editor()
    state.windows = normalize_windows(config_editor_windows());
    rebuild_window_lookups();
    sync_config_editor_from_windows(true);
    state.config_message = 'Applied.';
    state.config_message_color = COLORS.success;
    mark_windows_scroll_to_bottom();
end

local function save_config()
    local windows = normalize_windows(config_editor_windows());
    local path = config_file_path();
    local dir_ok, dir_or_error = ensure_config_dir();
    if (dir_ok) then
        path = path_join(dir_or_error, 'ashitachat_config.lua');
    elseif (config_dir_path() ~= nil) then
        return false, ('Save failed: %s'):fmt(tostring(dir_or_error));
    end

    local write_ok, write_error = write_text_file(path, config_text_from_windows(windows));
    if (not write_ok) then
        return false, tostring(write_error or 'open failed');
    end

    state.windows = windows;
    rebuild_window_lookups();
    sync_config_editor_from_windows(false);
    state.config_message = 'Saved.';
    state.config_message_color = COLORS.success;
    mark_windows_scroll_to_bottom();
    return true, ('Saved %s.'):fmt(path);
end

local function reset_config_editor_to_defaults()
    local used_keys = {};
    state.config_windows = {};
    for index, window in ipairs(DEFAULT_WINDOWS) do
        table.insert(state.config_windows, editor_from_window(normalize_window(window, index, used_keys), index));
    end
    state.config_selected_window = 1;
    state.config_dirty = true;
    state.config_message = 'Reset pending.';
    state.config_message_color = COLORS.status;
end

local function mark_config_dirty()
    state.config_dirty = true;
    state.config_message = nil;
    state.config_message_color = nil;
end

local function rebuild_window_tab_lookup(window)
    window.tab_by_key = {};
    for index, tab in ipairs(window.tabs) do
        tab.index = index;
        window.tab_by_key[tab.key] = tab;
    end

    if ((window.selected_tab == nil or window.tab_by_key[window.selected_tab] == nil) and #window.tabs > 0) then
        window.selected_tab = window.tabs[1].key;
    end
end

function rebuild_window_lookups()
    state.window_by_key = {};
    for index, window in ipairs(state.windows) do
        window.index = index;
        rebuild_window_tab_lookup(window);
        state.window_by_key[window.key] = window;
    end

    state.config_selected_window = math.floor(tonumber(state.config_selected_window) or 1);
    if (state.config_selected_window < 1 or state.config_selected_window > #state.windows) then
        state.config_selected_window = 1;
    end
end

local function configured_tabs(config)
    if (type(config) ~= 'table') then
        return nil;
    end

    if (type(config.tabs) == 'table') then
        return config.tabs;
    end

    if (type(config.settings) == 'table' and type(config.settings.tabs) == 'table') then
        return config.settings.tabs;
    end

    return nil;
end

local function configured_windows(config)
    if (type(config) ~= 'table') then
        return nil;
    end

    if (type(config.windows) == 'table') then
        return config.windows;
    end

    if (type(config.settings) == 'table' and type(config.settings.windows) == 'table') then
        return config.settings.windows;
    end

    local tabs = configured_tabs(config);
    if (tabs ~= nil) then
        return {
            { key = 'main', label = 'Main', visible = true, tabs = tabs },
        };
    end

    return nil;
end

local function migrate_legacy_config()
    local path = config_file_path();
    local legacy_path = legacy_config_file_path();
    if (legacy_path == path or file_exists(path) or not file_exists(legacy_path)) then
        return false;
    end

    local dir_ok = ensure_config_dir();
    if (not dir_ok) then
        return false;
    end

    local contents = read_text_file(legacy_path);
    if (contents == nil) then
        return false;
    end

    local write_ok = write_text_file(path, contents);
    return write_ok == true;
end

local function load_config()
    state.config_error = nil;
    package.loaded.ashitachat_config = nil;

    local path = config_file_path();
    local ok, config, error_message = false, nil, nil;

    if (not file_exists(path)) then
        migrate_legacy_config();
    end

    ok, config, error_message = load_lua_config_file(path);
    if (not ok and not file_exists(path)) then
        local legacy_path = legacy_config_file_path();
        if (legacy_path ~= path) then
            ok, config, error_message = load_lua_config_file(legacy_path);
        end
    end

    if (not ok) then
        state.config_error = tostring(error_message or config);
        state.windows = normalize_windows(DEFAULT_WINDOWS);
    else
        state.windows = normalize_windows(configured_windows(config));
    end

    rebuild_window_lookups();
    sync_config_editor_from_windows(false);
    mark_windows_scroll_to_bottom();
end

local function filters_summary(tab)
    local parts = {};

    for _, filter in ipairs(tab.filters or {}) do
        table.insert(parts, filter);
    end

    for _, mode in ipairs(tab.modes or {}) do
        table.insert(parts, ('mode:%d'):fmt(mode));
    end

    for _, needle in ipairs(tab.contains or {}) do
        table.insert(parts, ('contains:%s'):fmt(needle));
    end

    if (#parts == 0) then
        return 'none';
    end

    return table.concat(parts, ',');
end

local function find_window(value)
    local text = trim_string(value);
    if (text == '') then
        return nil;
    end

    local index = tonumber(text);
    if (index ~= nil and state.windows[math.floor(index)] ~= nil) then
        return state.windows[math.floor(index)];
    end

    local key = normalize_key(text, '');
    if (state.window_by_key[key] ~= nil) then
        return state.window_by_key[key];
    end

    local lower = text:lower();
    for _, window in ipairs(state.windows) do
        if (window.label:lower() == lower) then
            return window;
        end
    end

    return nil;
end

local function find_tab(window, value)
    local text = trim_string(value);
    if (window == nil or text == '') then
        return nil;
    end

    local index = tonumber(text);
    if (index ~= nil and window.tabs[math.floor(index)] ~= nil) then
        return window.tabs[math.floor(index)];
    end

    local key = normalize_key(text, '');
    if (window.tab_by_key[key] ~= nil) then
        return window.tab_by_key[key];
    end

    local lower = text:lower();
    for _, tab in ipairs(window.tabs) do
        if (tab.label:lower() == lower) then
            return tab;
        end
    end

    return nil;
end

local function log_info(message)
    print(chat.header(addon.name):append(chat.message(message)));
end

local function log_warn(message)
    print(chat.header(addon.name):append(chat.warning(message)));
end

local function is_injected(e)
    return e.injected == true;
end

local function is_ashitachat_message(message)
    return type(message) == 'string' and message:lower():find('%[ashitachat%]') ~= nil;
end

local function chat_mode(e)
    return bit.band(tonumber(e.mode) or 0, 0x000000FF);
end

local function chat_display_mode(e)
    return bit.band(tonumber(e.mode_modified or e.mode) or 0, 0x000000FF);
end

local function clean_message(message)
    local text = tostring(message or ''):gsub('\r', ' '):gsub('\n', ' '):gsub('%z', '');

    text = text:gsub('.', function (character)
        local value = character:byte();
        if (value ~= nil and value < 32 and value ~= 9) then
            return '';
        end
        return character;
    end);

    return trim_string(text);
end

local function lower_text(value)
    return clean_message(value):lower();
end

local function classify_message(mode, text)
    local lower = lower_text(text);

    if (lower:find('partyfinder', 1, true) ~= nil
        or lower:find('looking for group', 1, true) ~= nil
        or lower:find('looking for members', 1, true) ~= nil
        or lower:find('seeking members', 1, true) ~= nil
        or lower:find('recruit', 1, true) ~= nil
        or lower:find('static', 1, true) ~= nil
        or lower:find('exp party', 1, true) ~= nil
        or lower:find('cp party', 1, true) ~= nil
        or lower:find('%f[%w]lfg%f[%W]') ~= nil
        or lower:find('%f[%w]lfm%f[%W]') ~= nil) then
        return 'lfg';
    end

    if (mode == 4 or mode == 5 or mode == 12 or mode == 13 or mode == 210) then
        return 'group';
    end

    if (COMBAT_MODES[mode] == true
        or lower:find('starts casting', 1, true) ~= nil
        or lower:find('readies ', 1, true) ~= nil
        or lower:find('skillchain', 1, true) ~= nil
        or lower:find('takes ', 1, true) ~= nil
        or lower:find('points of damage', 1, true) ~= nil
        or lower:find('gains the effect', 1, true) ~= nil
        or lower:find('loses the effect', 1, true) ~= nil
        or lower:find('is defeated', 1, true) ~= nil) then
        return 'combat';
    end

    return 'general';
end

local function display_text(mode, text)
    return text;
end

local function message_color(mode, category)
    return MODE_COLORS[mode] or COLORS[category] or COLORS.general;
end

local function history_text()
    local lines = {
        'return {',
        '    version = 1,',
        '    messages = {',
    };
    local first = math.max(1, #state.messages - HISTORY_MESSAGE_LIMIT + 1);

    for index = first, #state.messages do
        local message = state.messages[index];
        table.insert(lines, ('        { time = %s, mode = %d, display_mode = %d, text = %s, display = %s },'):fmt(
            config_string(message.time),
            bit.band(tonumber(message.mode) or 0, 0x000000FF),
            bit.band(tonumber(message.display_mode) or 0, 0x000000FF),
            config_string(message.text),
            config_string(message.display)));
    end

    table.insert(lines, '    },');
    table.insert(lines, '};');
    table.insert(lines, '');
    return table.concat(lines, '\n');
end

local function save_history()
    local path = history_file_path();
    if (path == nil) then
        return false, 'Ashita config path is unavailable.';
    end

    local dir_ok, dir_or_error = ensure_config_dir();
    if (not dir_ok) then
        return false, tostring(dir_or_error);
    end

    return write_text_file(path_join(dir_or_error, 'ashitachat_history.lua'), history_text());
end

local function load_history()
    local path = history_file_path();
    if (path == nil or not file_exists(path)) then
        return 0, nil;
    end

    local ok, history, error_message = load_lua_config_file(path);
    if (not ok or type(history) ~= 'table' or type(history.messages) ~= 'table') then
        return 0, tostring(error_message or 'History file is invalid.');
    end

    state.messages = {};
    state.message_seq = 0;
    local first = math.max(1, #history.messages - HISTORY_MESSAGE_LIMIT + 1);
    for index = first, #history.messages do
        local saved = history.messages[index];
        if (type(saved) == 'table' and type(saved.text) == 'string') then
            local mode = bit.band(tonumber(saved.mode) or 0, 0x000000FF);
            local display_mode = bit.band(tonumber(saved.display_mode) or mode, 0x000000FF);
            local text = clean_message(saved.text);
            local display = clean_message(saved.display or text);
            if (text ~= '') then
                local category = classify_message(display_mode, text);
                state.message_seq = state.message_seq + 1;
                table.insert(state.messages, {
                    id = state.message_seq,
                    time = type(saved.time) == 'string' and saved.time:match('^%d%d:%d%d:%d%d$') and saved.time or os.date('%H:%M:%S'),
                    mode = mode,
                    display_mode = display_mode,
                    category = category,
                    text = text,
                    display = display,
                    search_text = (display .. ' ' .. text):lower(),
                    color = message_color(display_mode, category),
                });
            end
        end
    end

    mark_windows_scroll_to_bottom();
    return #state.messages, nil;
end

local function normalized_search(window)
    if (window.show_search ~= true) then
        return '';
    end

    return trim_string(window.search_buffer[1]):lower();
end

local function message_matches_search(message, query)
    if (query == nil or query == '') then
        return true;
    end

    return message.search_text:find(query, 1, true) ~= nil;
end

local function message_matches_tab(message, tab)
    if (tab == nil) then
        return false;
    end

    if ((tab.filters or {}).all == true) then
        return true;
    end

    if ((tab.filters or {})[message.category] == true) then
        return true;
    end

    if ((tab.mode_map or {})[message.mode] == true or (tab.mode_map or {})[message.display_mode] == true) then
        return true;
    end

    for _, needle in ipairs(tab.contains or {}) do
        if (message.search_text:find(needle, 1, true) ~= nil) then
            return true;
        end
    end

    return false;
end

local function message_matches_window(message, window)
    if (window == nil) then
        return false;
    end

    local selected_tab = window.tab_by_key[window.selected_tab] or window.tabs[1];
    return message_matches_tab(message, selected_tab)
        and message_matches_search(message, normalized_search(window));
end

local function mark_matching_windows_scroll_to_bottom(message)
    for _, window in ipairs(state.windows) do
        if (message_matches_window(message, window)) then
            window.scroll_to_bottom = true;
        end
    end
end

local function append_message(e)
    if (is_injected(e)) then
        return false;
    end

    local mode = chat_mode(e);
    local display_mode = chat_display_mode(e);
    -- NPC dialog is emitted once in its original 150-152 modes, then
    -- reinjected for the legacy chat windows in mode 190. Capture the
    -- original event and ignore the reinjections so replacement windows do
    -- not show the same NPC line twice.
    if (mode == 190 or display_mode == 190) then
        return false;
    end

    local text = clean_message(e.message);
    if (text == '') then
        return false;
    end

    local category = classify_message(display_mode, text);
    local display = display_text(display_mode, text);

    state.message_seq = state.message_seq + 1;
    local message = {
        id = state.message_seq,
        time = os.date('%H:%M:%S'),
        mode = mode,
        display_mode = display_mode,
        category = category,
        text = text,
        display = display,
        search_text = (display .. ' ' .. text):lower(),
        color = message_color(display_mode, category),
    };
    table.insert(state.messages, message);

    while (#state.messages > state.max_messages) do
        table.remove(state.messages, 1);
    end

    mark_matching_windows_scroll_to_bottom(message);
    return true;
end

local function push_tab_style(active)
    imgui.PushStyleColor(IMGUI.col_button, active and COLORS.tab_active or COLORS.tab);
    imgui.PushStyleColor(IMGUI.col_button_hovered, COLORS.tab_hover);
    imgui.PushStyleColor(IMGUI.col_button_active, COLORS.tab_active);
    imgui.PushStyleColor(IMGUI.col_text, active and COLORS.tab_text_active or COLORS.tab_text);
end

local function pop_tab_style()
    imgui.PopStyleColor(4);
end

local function color_with_alpha(color, alpha)
    return {
        color[1] or 0.0,
        color[2] or 0.0,
        color[3] or 0.0,
        normalize_float(alpha, color[4] or 1.0, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX),
    };
end

local function window_id(window)
    return window.key or tostring(window.index or 'window');
end

local function sync_editor_window_layout(window)
    local row = state.config_windows[window.index or 0];
    if (row == nil) then
        return;
    end

    local key = normalize_key(row.key_buffer and row.key_buffer[1] or '', '');
    if (key ~= window.key) then
        return;
    end

    row.window_x = window.window_x;
    row.window_y = window.window_y;
    row.window_width = window.window_width;
    row.window_height = window.window_height;
end

local function track_window_layout(window)
    if (type(imgui.GetWindowPos) == 'function') then
        local x, y = imgui.GetWindowPos();
        window.window_x = normalize_int(x, window.window_x or DEFAULT_WINDOW_X, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX);
        window.window_y = normalize_int(y, window.window_y or DEFAULT_WINDOW_Y, WINDOW_POSITION_MIN, WINDOW_POSITION_MAX);
    end

    local width, height = nil, nil;
    if (type(imgui.GetWindowSize) == 'function') then
        width, height = imgui.GetWindowSize();
        if (type(width) == 'table') then
            local size = width;
            width = size.x or size[1];
            height = size.y or size[2];
        end
    end
    if (width == nil and type(imgui.GetWindowWidth) == 'function') then
        width = imgui.GetWindowWidth();
    end
    if (height == nil and type(imgui.GetWindowHeight) == 'function') then
        height = imgui.GetWindowHeight();
    end

    window.window_width = normalize_int(width, window.window_width or DEFAULT_WINDOW_WIDTH, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX);
    window.window_height = normalize_int(height, window.window_height or DEFAULT_WINDOW_HEIGHT, WINDOW_SIZE_MIN, WINDOW_SIZE_MAX);
    sync_editor_window_layout(window);
end

local function render_tabs(window)
    local id = window_id(window);
    for index, tab in ipairs(window.tabs) do
        if (index > 1) then
            imgui.SameLine(0, 2);
        end

        local active = window.selected_tab == tab.key;
        push_tab_style(active);
        if (imgui.Button(('%s##ashitachat_%s_tab_%s'):fmt(tab.label, id, tab.key), { 98, 20 })) then
            window.selected_tab = tab.key;
            window.scroll_to_bottom = true;
        end
        pop_tab_style();
    end
end

local function render_search(window, inline)
    local width = type(imgui.GetWindowWidth) == 'function' and imgui.GetWindowWidth() or 760;
    if (inline == true and width >= 650) then
        imgui.SameLine(0, 14);
    end

    local id = window_id(window);
    imgui.PushItemWidth(160);
    imgui.InputText(('##ashitachat_%s_search'):fmt(id), window.search_buffer, 64);
    imgui.PopItemWidth();

    if (trim_string(window.search_buffer[1]) ~= '') then
        imgui.SameLine(0, 4);
        if (imgui.Button(('x##ashitachat_%s_search_clear'):fmt(id), { 20, 20 })) then
            buffer_set(window.search_buffer, '');
            window.scroll_to_bottom = true;
        end
    end
end

local function begin_child(id, size, border, flags)
    local child_open = false;
    local child_visible = true;

    if (type(imgui.BeginChild) == 'function' and type(imgui.EndChild) == 'function') then
        if (flags ~= nil and flags ~= 0) then
            local ok, result = pcall(imgui.BeginChild, id, size, border, flags);
            if (ok) then
                child_open = true;
                child_visible = result ~= false;
                return child_open, child_visible;
            end
        end

        local ok, result = pcall(imgui.BeginChild, id, size, border);
        child_open = ok;
        child_visible = (not ok) or result ~= false;
    end

    return child_open, child_visible;
end

local function text_colored_wrapped(color, text)
    local wrapped = type(imgui.PushTextWrapPos) == 'function' and type(imgui.PopTextWrapPos) == 'function';

    if (wrapped) then
        imgui.PushTextWrapPos(0.0);
    end

    imgui.TextColored(color, text);

    if (wrapped) then
        imgui.PopTextWrapPos();
    end
end

local function render_message(message)
    imgui.TextColored(COLORS.timestamp, ('[%s]'):fmt(message.time));
    imgui.SameLine(0, 4);
    text_colored_wrapped(message.color, message.display);
end

local function render_message_list(window)
    local query = normalized_search(window);
    local selected_tab = window.tab_by_key[window.selected_tab] or window.tabs[1];
    local child_height = window.show_footer == true and -24 or 0;
    local child_flags = window.show_scrollbar == true and 0 or IMGUI.window_no_scrollbar;
    local child_open, child_visible = begin_child(('##ashitachat_%s_message_list'):fmt(window_id(window)), { 0, child_height }, false, child_flags);
    local visible_count = 0;

    if (child_visible) then
        if (query ~= '') then
            imgui.TextColored(COLORS.status, ('Find Results: %s'):fmt(query));
            imgui.Separator();
        end

        for _, message in ipairs(state.messages) do
            if (message_matches_tab(message, selected_tab) and message_matches_search(message, query)) then
                render_message(message);
                visible_count = visible_count + 1;
            end
        end

        if (visible_count == 0) then
            imgui.TextColored(COLORS.empty, query ~= '' and 'No matches.' or 'No chat lines yet.');
        end

        if (window.scroll_to_bottom and type(imgui.SetScrollHereY) == 'function') then
            imgui.SetScrollHereY(1.0);
        end
    end

    if (child_open) then
        imgui.EndChild();
    end

    window.scroll_to_bottom = false;
    return visible_count;
end

local function render_footer(window, visible_count)
    local id = window_id(window);
    imgui.TextColored(COLORS.status, ('%d shown / %d buffered'):fmt(visible_count, #state.messages));
    imgui.SameLine(0, 10);
    imgui.TextColored(COLORS.status, state.hide_native and 'native hidden' or 'native visible');
    imgui.SameLine(0, 10);
    if (imgui.Button(('v##ashitachat_%s_scroll_bottom'):fmt(id), { 22, 0 })) then
        window.scroll_to_bottom = true;
    end
    imgui.SameLine(0, 6);
    if (imgui.Button(('cfg##ashitachat_%s_open_config'):fmt(id), { 34, 0 })) then
        state.config_visible[1] = true;
        state.config_selected_window = window.index or 1;
    end
    imgui.SameLine(0, 6);
    local native_action = state.hide_native and 'show orig' or 'hide orig';
    if (imgui.Button(('%s##ashitachat_%s_toggle_native'):fmt(native_action, id), { 66, 0 })) then
        set_hidden(not state.hide_native);
    end
end

local function render_chat_window(window)
    if (state.ui_visible[1] ~= true or window.visible[1] ~= true) then
        return;
    end

    local window_flags = bit.bor(IMGUI.window_no_title_bar, IMGUI.window_no_collapse);
    if (window.show_scrollbar ~= true) then
        window_flags = bit.bor(window_flags, IMGUI.window_no_scrollbar);
    end

    local show_border = window.show_border == true;
    imgui.SetNextWindowPos({ window.window_x, window.window_y }, IMGUI.cond_first_use);
    imgui.SetNextWindowSize({ window.window_width, window.window_height }, IMGUI.cond_first_use);
    imgui.PushStyleVar(IMGUI.style_window_padding, { 6, 4 });
    imgui.PushStyleVar(IMGUI.style_window_border_size, show_border and 1.0 or 0.0);
    imgui.PushStyleVar(IMGUI.style_frame_padding, { 5, 2 });
    imgui.PushStyleColor(IMGUI.col_window_bg, color_with_alpha(COLORS.panel_bg, window.background_opacity));
    imgui.PushStyleColor(IMGUI.col_child_bg, COLORS.child_bg);
    imgui.PushStyleColor(IMGUI.col_border, show_border and COLORS.border or color_with_alpha(COLORS.border, 0.0));
    imgui.PushStyleColor(IMGUI.col_frame_bg, COLORS.frame);
    imgui.PushStyleColor(IMGUI.col_frame_bg_hovered, COLORS.frame_hover);

    if (imgui.Begin(('AshitaChat - %s###AshitaChatWindow_%s'):fmt(window.label, window_id(window)), window.visible, window_flags)) then
        track_window_layout(window);

        if (type(imgui.SetWindowFontScale) == 'function') then
            imgui.SetWindowFontScale(state.font_scale);
        end

        local controls_visible = false;
        if (window.show_tabs == true) then
            render_tabs(window);
            controls_visible = true;
        end
        if (window.show_search == true) then
            render_search(window, controls_visible);
            controls_visible = true;
        end
        if (controls_visible) then
            imgui.Separator();
        end

        local visible_count = render_message_list(window);
        if (window.show_footer == true) then
            render_footer(window, visible_count);
        end
    end

    imgui.End();
    imgui.PopStyleColor(5);
    imgui.PopStyleVar(3);
end

local function render_chat_windows()
    for _, window in ipairs(state.windows) do
        render_chat_window(window);
    end
end

local function selected_config_window_index()
    if (#state.config_windows == 0) then
        return nil;
    end

    local index = math.floor(tonumber(state.config_selected_window) or 1);
    if (index < 1) then
        index = 1;
    elseif (index > #state.config_windows) then
        index = #state.config_windows;
    end
    state.config_selected_window = index;
    return index;
end

local function selected_config_window()
    local index = selected_config_window_index();
    if (index == nil) then
        return nil, nil;
    end

    return index, state.config_windows[index];
end

local function add_config_window()
    local index = #state.config_windows + 1;
    table.insert(state.config_windows, editor_from_window({
        key = ('window%d'):fmt(index),
        label = ('Window %d'):fmt(index),
        visible = true,
        tabs = {
            { key = 'general', label = 'General', filters = { 'all' } },
        },
    }, index));
    state.config_selected_window = index;
    mark_config_dirty();
end

local function move_config_window(index, offset)
    local target = index + offset;
    if (state.config_windows[index] == nil or state.config_windows[target] == nil) then
        return;
    end

    state.config_windows[index], state.config_windows[target] = state.config_windows[target], state.config_windows[index];
    if (state.config_selected_window == index) then
        state.config_selected_window = target;
    elseif (state.config_selected_window == target) then
        state.config_selected_window = index;
    end
    mark_config_dirty();
end

local function remove_config_window(index)
    if (#state.config_windows <= 1 or state.config_windows[index] == nil) then
        return;
    end

    table.remove(state.config_windows, index);
    if (state.config_selected_window > #state.config_windows) then
        state.config_selected_window = #state.config_windows;
    end
    mark_config_dirty();
end

local function add_config_tab(window_index)
    local window_row = state.config_windows[window_index];
    if (window_row == nil) then
        return;
    end

    local index = #window_row.tabs + 1;
    table.insert(window_row.tabs, editor_from_tab({
        key = ('tab%d'):fmt(index),
        label = ('Tab %d'):fmt(index),
        filters = { 'general' },
        modes = {},
        contains = {},
    }, index));
    mark_config_dirty();
end

local function move_config_tab(window_index, index, offset)
    local window_row = state.config_windows[window_index];
    if (window_row == nil) then
        return;
    end

    local target = index + offset;
    if (window_row.tabs[index] == nil or window_row.tabs[target] == nil) then
        return;
    end

    window_row.tabs[index], window_row.tabs[target] = window_row.tabs[target], window_row.tabs[index];
    mark_config_dirty();
end

local function remove_config_tab(window_index, index)
    local window_row = state.config_windows[window_index];
    if (window_row == nil or #window_row.tabs <= 1 or window_row.tabs[index] == nil) then
        return;
    end

    table.remove(window_row.tabs, index);
    mark_config_dirty();
end

local function render_config_filter_checkbox(row, window_index, tab_index, filter)
    local enabled = row.filters[filter] == true;
    if (imgui.Checkbox(('%s##ashitachat_config_window_%d_tab_%d_filter_%s'):fmt(filter, window_index, tab_index, filter), { enabled })) then
        local next_enabled = not enabled;
        row.filters[filter] = next_enabled;

        if (filter == 'all' and next_enabled) then
            for _, other in ipairs(FILTER_ORDER) do
                if (other ~= 'all') then
                    row.filters[other] = false;
                end
            end
        elseif (filter ~= 'all' and next_enabled) then
            row.filters.all = false;
        end

        mark_config_dirty();
    end
end

local function render_config_mode_checkbox(row, window_index, tab_index, mode_filter)
    local enabled = mode_group_enabled(row, mode_filter.modes);
    if (imgui.Checkbox(('%s##ashitachat_config_window_%d_tab_%d_mode_%s'):fmt(mode_filter.label, window_index, tab_index, mode_filter.key), { enabled })) then
        set_mode_group_enabled(row, mode_filter.modes, not enabled);
        mark_config_dirty();
    end
end

local function render_config_tab_editor(window_index, index, row)
    imgui.Separator();
    imgui.TextColored(COLORS.tab_text, ('Tab %d'):fmt(index));
    imgui.SameLine(0, 8);
    if (imgui.Button(('Up##ashitachat_config_window_%d_tab_%d_up'):fmt(window_index, index), { 42, 0 })) then
        move_config_tab(window_index, index, -1);
        return;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Down##ashitachat_config_window_%d_tab_%d_down'):fmt(window_index, index), { 54, 0 })) then
        move_config_tab(window_index, index, 1);
        return;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Remove##ashitachat_config_window_%d_tab_%d_remove'):fmt(window_index, index), { 70, 0 })) then
        remove_config_tab(window_index, index);
        return;
    end

    imgui.PushItemWidth(160);
    if (imgui.InputText(('Key##ashitachat_config_window_%d_tab_%d_key'):fmt(window_index, index), row.key_buffer, 32)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.SameLine(0, 12);
    imgui.PushItemWidth(220);
    if (imgui.InputText(('Label##ashitachat_config_window_%d_tab_%d_label'):fmt(window_index, index), row.label_buffer, 48)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.TextColored(COLORS.status, 'Filters');
    for filter_index, filter in ipairs(FILTER_ORDER) do
        if (filter_index > 1) then
            imgui.SameLine(0, 8);
        end
        render_config_filter_checkbox(row, window_index, index, filter);
    end

    imgui.TextColored(COLORS.status, 'Modes');
    sync_row_mode_map(row);
    for mode_index, mode_filter in ipairs(MODE_FILTERS) do
        if (mode_index > 1 and ((mode_index - 1) % 4) ~= 0) then
            imgui.SameLine(0, 8);
        end
        render_config_mode_checkbox(row, window_index, index, mode_filter);
    end

    imgui.PushItemWidth(520);
    if (imgui.InputText(('Mode IDs##ashitachat_config_window_%d_tab_%d_modes'):fmt(window_index, index), row.modes_buffer, 128)) then
        sync_row_mode_map(row);
        mark_config_dirty();
    end
    if (imgui.InputText(('Contains##ashitachat_config_window_%d_tab_%d_contains'):fmt(window_index, index), row.contains_buffer, 256)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();
end

local function render_config_window_selector()
    for index, row in ipairs(state.config_windows) do
        if (index > 1) then
            imgui.SameLine(0, 2);
        end

        local label = trim_string(row.label_buffer and row.label_buffer[1] or '');
        if (label == '') then
            label = ('Window %d'):fmt(index);
        end

        local active = state.config_selected_window == index;
        push_tab_style(active);
        if (imgui.Button(('%s##ashitachat_config_select_window_%d'):fmt(label, index), { 112, 20 })) then
            state.config_selected_window = index;
        end
        pop_tab_style();
    end
end

local function render_config_window_editor(index, row)
    if (row.background_opacity_buffer == nil) then
        row.background_opacity = normalize_float(row.background_opacity, DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX);
        row.background_opacity_buffer = T{ ('%.2f'):fmt(row.background_opacity) };
    end

    imgui.TextColored(COLORS.tab_text, ('Window %d'):fmt(index));
    imgui.SameLine(0, 8);
    if (imgui.Button(('Up##ashitachat_config_window_%d_up'):fmt(index), { 42, 0 })) then
        move_config_window(index, -1);
        return false;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Down##ashitachat_config_window_%d_down'):fmt(index), { 54, 0 })) then
        move_config_window(index, 1);
        return false;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Remove##ashitachat_config_window_%d_remove'):fmt(index), { 70, 0 })) then
        remove_config_window(index);
        return false;
    end
    imgui.SameLine(0, 10);
    local visible = row.visible ~= false;
    if (imgui.Checkbox(('Visible##ashitachat_config_window_%d_visible'):fmt(index), { visible })) then
        row.visible = not visible;
        mark_config_dirty();
    end

    imgui.PushItemWidth(160);
    if (imgui.InputText(('Key##ashitachat_config_window_%d_key'):fmt(index), row.key_buffer, 32)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.SameLine(0, 12);
    imgui.PushItemWidth(220);
    if (imgui.InputText(('Label##ashitachat_config_window_%d_label'):fmt(index), row.label_buffer, 48)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.TextColored(COLORS.status, 'Chrome');
    local show_tabs = row.show_tabs ~= false;
    if (imgui.Checkbox(('Tabs##ashitachat_config_window_%d_show_tabs'):fmt(index), { show_tabs })) then
        row.show_tabs = not show_tabs;
        mark_config_dirty();
    end
    imgui.SameLine(0, 8);
    local show_search = row.show_search ~= false;
    if (imgui.Checkbox(('Search##ashitachat_config_window_%d_show_search'):fmt(index), { show_search })) then
        row.show_search = not show_search;
        mark_config_dirty();
    end
    imgui.SameLine(0, 8);
    local show_footer = row.show_footer ~= false;
    if (imgui.Checkbox(('Footer##ashitachat_config_window_%d_show_footer'):fmt(index), { show_footer })) then
        row.show_footer = not show_footer;
        mark_config_dirty();
    end
    imgui.SameLine(0, 8);
    local show_border = row.show_border ~= false;
    if (imgui.Checkbox(('Border##ashitachat_config_window_%d_show_border'):fmt(index), { show_border })) then
        row.show_border = not show_border;
        mark_config_dirty();
    end
    imgui.SameLine(0, 8);
    local show_scrollbar = row.show_scrollbar ~= false;
    if (imgui.Checkbox(('Scrollbar##ashitachat_config_window_%d_show_scrollbar'):fmt(index), { show_scrollbar })) then
        row.show_scrollbar = not show_scrollbar;
        mark_config_dirty();
    end
    imgui.SameLine(0, 12);
    imgui.PushItemWidth(64);
    if (imgui.InputText(('Opacity##ashitachat_config_window_%d_background_opacity'):fmt(index), row.background_opacity_buffer, 8)) then
        row.background_opacity = normalize_float(row.background_opacity_buffer[1], row.background_opacity or DEFAULT_BACKGROUND_OPACITY, BACKGROUND_OPACITY_MIN, BACKGROUND_OPACITY_MAX);
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    return true;
end

local function render_config_window()
    if (state.config_visible[1] ~= true) then
        return;
    end

    imgui.SetNextWindowSize({ 760, 560 }, IMGUI.cond_first_use);
    local flags = bit.bor(IMGUI.window_no_collapse, IMGUI.window_always_auto_resize);
    if (imgui.Begin('AshitaChat Configuration###AshitaChatConfig', state.config_visible, flags)) then
        local window_index, window_row = selected_config_window();

        if (imgui.Button('Add Window##ashitachat_config_add_window')) then
            add_config_window();
            window_index, window_row = selected_config_window();
        end
        imgui.SameLine(0, 8);
        if (imgui.Button('Add Tab##ashitachat_config_add_tab')) then
            add_config_tab(window_index);
        end
        imgui.SameLine(0, 8);
        if (imgui.Button('Apply##ashitachat_config_apply')) then
            apply_config_editor();
        end
        imgui.SameLine(0, 4);
        if (imgui.Button('Save##ashitachat_config_save')) then
            local ok, message = save_config();
            if (ok) then
                log_info(message);
            else
                state.config_message = 'Save failed.';
                state.config_message_color = COLORS.error;
                log_warn(message);
            end
        end
        imgui.SameLine(0, 4);
        if (imgui.Button('Reload##ashitachat_config_reload')) then
            load_config();
            state.config_message = 'Reloaded.';
            state.config_message_color = COLORS.success;
        end
        imgui.SameLine(0, 4);
        if (imgui.Button('Defaults##ashitachat_config_defaults')) then
            reset_config_editor_to_defaults();
        end

        if (state.config_dirty) then
            imgui.SameLine(0, 8);
            imgui.TextColored(COLORS.tab_text, 'Unsaved');
        end

        if (state.config_message ~= nil) then
            imgui.SameLine(0, 8);
            imgui.TextColored(state.config_message_color or COLORS.status, state.config_message);
        end

        imgui.Separator();
        imgui.TextColored(COLORS.status, config_file_path());

        render_config_window_selector();
        imgui.Separator();

        window_index, window_row = selected_config_window();
        if (window_row ~= nil and render_config_window_editor(window_index, window_row)) then
            local child_open, child_visible = begin_child('##ashitachat_config_tab_list', { 0, 390 }, true);
            if (child_visible) then
                for index, row in ipairs(window_row.tabs) do
                    render_config_tab_editor(window_index, index, row);
                end
            end
            if (child_open) then
                imgui.EndChild();
            end
        end
    end
    imgui.End();
end

local function mode_summary()
    local modes = {};

    for mode, count in pairs(state.mode_counts) do
        table.insert(modes, {
            mode = mode,
            count = count,
        });
    end

    table.sort(modes, function (left, right)
        return left.mode < right.mode;
    end);

    if (#modes == 0) then
        return 'none';
    end

    local parts = {};
    for _, entry in ipairs(modes) do
        table.insert(parts, string.format('%d:%d', entry.mode, entry.count));
    end

    return table.concat(parts, ', ');
end

local function total_tab_count()
    local count = 0;
    for _, window in ipairs(state.windows) do
        count = count + #window.tabs;
    end

    return count;
end

local function visible_window_count()
    local count = 0;
    for _, window in ipairs(state.windows) do
        if (window.visible[1] == true) then
            count = count + 1;
        end
    end

    return count;
end

local function ensure_any_window_visible()
    if (#state.windows == 0) then
        return;
    end

    if (visible_window_count() == 0) then
        state.windows[1].visible[1] = true;
    end
end

local function selected_tabs_summary()
    local parts = {};
    for _, window in ipairs(state.windows) do
        table.insert(parts, ('%s:%s'):fmt(window.key, window.selected_tab or 'none'));
    end

    if (#parts == 0) then
        return 'none';
    end

    return table.concat(parts, ', ');
end

set_hidden = function(hidden)
    state.hide_native = hidden == true;

    if (state.hide_native) then
        state.ui_visible[1] = true;
        ensure_any_window_visible();
        log_info('Native chat lines are blocked. Legacy UI windows remain available for menus and chat input.');
    else
        log_info('Native chat lines are visible.');
    end
end

local function print_windows()
    for _, window in ipairs(state.windows) do
        log_info(('%d. %s (%s): %s, tabs=%d, selected=%s'):fmt(
            window.index,
            window.label,
            window.key,
            window.visible[1] and 'visible' or 'hidden',
            #window.tabs,
            window.selected_tab or 'none'));
    end
end

local function print_tabs(window)
    if (window == nil) then
        for _, entry in ipairs(state.windows) do
            log_info(('%s (%s) tabs:'):fmt(entry.label, entry.key));
            print_tabs(entry);
        end
        return;
    end

    for _, tab in ipairs(window.tabs) do
        log_info(('%d. %s (%s): %s'):fmt(tab.index, tab.label, tab.key, filters_summary(tab)));
    end
end

local function print_help()
    log_info('Commands:');
    log_info('/ashitachat hide - Block non-injected incoming chat lines from the native log.');
    log_info('/ashitachat show - Stop blocking native chat lines.');
    log_info('/ashitachat toggle - Toggle native chat-line blocking.');
    log_info('/ashitachat ui - Toggle all replacement chat windows.');
    log_info('/ashitachat window <key|number> [show|hide|toggle] - Change one replacement chat window.');
    log_info('/ashitachat config - Toggle the in-game tab configuration window.');
    log_info('/ashitachat clear - Clear the replacement chat buffer.');
    log_info('/ashitachat tab <tab> [window] - Switch replacement chat tabs.');
    log_info('/ashitachat tabs [window] - List configured replacement chat tabs.');
    log_info('/ashitachat windows - List configured replacement chat windows.');
    log_info('/ashitachat reload - Reload ashitachat_config.lua.');
    log_info('/ashitachat status - Show trial status and blocked-line count.');
end

local function print_status()
    log_info(string.format(
        'Status: nativeChat=%s, overlay=%s, windows=%d/%d visible, tabs=%d, selected=%s, config=%s, bufferedLines=%d, blockedLines=%d, modes=%s.',
        state.hide_native and 'hidden' or 'visible',
        state.ui_visible[1] and 'visible' or 'hidden',
        visible_window_count(),
        #state.windows,
        total_tab_count(),
        selected_tabs_summary(),
        state.config_error == nil and 'ready' or 'defaulted',
        #state.messages,
        state.blocked_count,
        mode_summary()));
end

ashita.events.register('load', 'load_cb', function ()
    load_config();
    local restored_count, history_error = load_history();
    set_hidden(true);
    if (state.config_error ~= nil) then
        log_warn('Using default tab config because ashitachat_config.lua did not load: ' .. state.config_error);
    end
    if (history_error ~= nil) then
        log_warn('Recent chat history did not load: ' .. history_error);
    elseif (restored_count > 0) then
        log_info(('Restored %d recent chat lines.'):fmt(restored_count));
    end
end);

ashita.events.register('unload', 'unload_cb', function ()
    save_history();
    state.hide_native = false;
    state.ui_visible[1] = false;
    state.config_visible[1] = false;
    for _, window in ipairs(state.windows) do
        window.visible[1] = false;
    end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    render_chat_windows();
    render_config_window();
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    local command = args[1] and args[1]:lower() or '';

    if (commands[command] ~= true) then
        return;
    end

    e.blocked = true;

    local action = args[2] and args[2]:lower() or 'status';

    if (action == 'hide' or action == 'on') then
        set_hidden(true);
    elseif (action == 'show' or action == 'off') then
        set_hidden(false);
    elseif (action == 'toggle') then
        set_hidden(not state.hide_native);
    elseif (action == 'ui') then
        state.ui_visible[1] = not state.ui_visible[1];
        if (state.ui_visible[1]) then
            ensure_any_window_visible();
        end
        log_info('Replacement chat windows are now ' .. (state.ui_visible[1] and 'visible.' or 'hidden.'));
    elseif (action == 'window') then
        local window = find_window(args[3]);
        if (args[3] == nil) then
            state.ui_visible[1] = not state.ui_visible[1];
            if (state.ui_visible[1]) then
                ensure_any_window_visible();
            end
            log_info('Replacement chat windows are now ' .. (state.ui_visible[1] and 'visible.' or 'hidden.'));
        elseif (window == nil) then
            log_warn('Unknown window. Use /ashitachat windows to list configured windows.');
        else
            local mode = args[4] and args[4]:lower() or 'toggle';
            if (mode == 'show' or mode == 'on') then
                window.visible[1] = true;
            elseif (mode == 'hide' or mode == 'off') then
                window.visible[1] = false;
            else
                window.visible[1] = not window.visible[1];
            end
            if (window.visible[1]) then
                state.ui_visible[1] = true;
            end
            log_info(('%s chat window is now %s.'):fmt(window.label, window.visible[1] and 'visible' or 'hidden'));
        end
    elseif (action == 'config' or action == 'settings') then
        local window = find_window(args[3]);
        if (window ~= nil) then
            state.config_selected_window = window.index or 1;
        end
        state.config_visible[1] = not state.config_visible[1];
        log_info('Configuration window is now ' .. (state.config_visible[1] and 'visible.' or 'hidden.'));
    elseif (action == 'clear') then
        state.messages = {};
        mark_windows_scroll_to_bottom();
        log_info('Replacement chat buffer cleared.');
    elseif (action == 'tab') then
        local window = state.windows[1];
        local tab_arg = args[3];
        local first_window = find_window(args[3]);
        if (first_window ~= nil and args[4] ~= nil) then
            window = first_window;
            tab_arg = args[4];
        elseif (args[4] ~= nil) then
            local second_window = find_window(args[4]);
            if (second_window ~= nil) then
                window = second_window;
            end
        end

        local tab = find_tab(window, tab_arg);
        if (tab == nil) then
            log_warn('Unknown tab. Use /ashitachat tabs [window] to list configured tabs.');
        else
            window.selected_tab = tab.key;
            window.scroll_to_bottom = true;
            log_info(('%s chat tab set to %s.'):fmt(window.label, tab.label));
        end
    elseif (action == 'tabs') then
        local window = find_window(args[3]);
        if (args[3] ~= nil and window == nil) then
            log_warn('Unknown window. Use /ashitachat windows to list configured windows.');
        else
            print_tabs(window);
        end
    elseif (action == 'windows') then
        print_windows();
    elseif (action == 'reload') then
        load_config();
        log_info(('Reloaded %d configured replacement chat windows with %d total tabs.'):fmt(#state.windows, total_tab_count()));
        if (state.config_error ~= nil) then
            log_warn('Using default tab config because ashitachat_config.lua did not load: ' .. state.config_error);
        end
    elseif (action == 'status') then
        print_status();
    elseif (action == 'help') then
        print_help();
    else
        log_warn('Unknown command. Use /ashitachat help.');
    end
end);

ashita.events.register('text_in', 'text_in_cb', function (e)
    if (e.blocked) then
        return;
    end

    if (is_ashitachat_message(e.message)) then
        return;
    end

    local mode = chat_mode(e);
    if (mode == 190) then
        -- FFXI reinjects native NPC/event dialog as mode 190 for its legacy
        -- chat window after the original 150-152 event has already driven
        -- the interactive cutscene state. Suppress only this rendered copy;
        -- blocking the original event prevents choice menus from appearing.
        if (state.hide_native == true) then
            state.blocked_count = state.blocked_count + 1;
            state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1;
            e.blocked = true;
        end
        return;
    end

    append_message(e);

    -- Native NPC dialog participates in the game's event UI flow. Blocking
    -- these modes can prevent choice menus (Home Points, Unity selection,
    -- and similar prompts) from becoming interactive, so always pass them
    -- through after capturing them for the replacement window.
    if (state.hide_native ~= true or NATIVE_DIALOG_MODES[mode] == true) then
        return;
    end

    if (not is_injected(e)) then
        state.blocked_count = state.blocked_count + 1;
        state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1;
        e.blocked = true;
    end
end);
