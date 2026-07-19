addon.name = 'ashitachat';
addon.author = 'EflfK';
addon.version = '0.1.0';
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

local VALID_FILTERS = {
    all = true,
    general = true,
    combat = true,
    group = true,
    lfg = true,
};

local FILTER_ORDER = { 'all', 'general', 'combat', 'group', 'lfg' };

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
    [11] = 'yell',
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
    selected_tab = 'general',
    tabs = {},
    tab_by_key = {},
    config_error = nil,
    config_tabs = {},
    config_dirty = false,
    config_message = nil,
    config_message_color = nil,
    search_buffer = T{ '' },
    messages = {},
    message_seq = 0,
    max_messages = 300,
    font_scale = 1.00,
    scroll_to_bottom = true,
    blocked_count = 0,
    pin_count = 0,
    pointer_error = nil,
    win_ptr1 = nil,
    win_ptr2 = nil,
    mode_counts = {},
};

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

local function config_file_path()
    local addon_path = trim_string(addon.path);
    if (addon_path ~= '') then
        return path_join(addon_path, 'ashitachat_config.lua');
    end

    local ok, install_path = pcall(function ()
        return AshitaCore:GetInstallPath();
    end);
    install_path = ok and trim_string(install_path) or '';
    if (install_path ~= '') then
        return path_join(path_join(install_path, 'addons\\ashitachat'), 'ashitachat_config.lua');
    end

    return 'ashitachat_config.lua';
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
        modes_buffer = T{ list_text(tab.modes) },
        contains_buffer = T{ list_text(tab.contains) },
    };
end

local function sync_config_editor_from_tabs(dirty)
    state.config_tabs = {};
    for index, tab in ipairs(state.tabs) do
        table.insert(state.config_tabs, editor_from_tab(tab, index));
    end

    state.config_dirty = dirty == true;
    state.config_message = nil;
    state.config_message_color = nil;
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

local function config_editor_tabs()
    local tabs = {};
    for index, row in ipairs(state.config_tabs) do
        table.insert(tabs, config_editor_tab(row, index));
    end

    return tabs;
end

local function config_text_from_tabs(tabs)
    local lines = {
        'return {',
        '    tabs = {',
    };

    for _, tab in ipairs(tabs or {}) do
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

        table.insert(lines, ('        { %s },'):fmt(table.concat(fields, ', ')));
    end

    table.insert(lines, '    },');
    table.insert(lines, '};');
    table.insert(lines, '');

    return table.concat(lines, '\n');
end

local rebuild_tab_lookup;

local function apply_config_editor()
    state.tabs = normalize_tabs(config_editor_tabs());
    rebuild_tab_lookup();
    sync_config_editor_from_tabs(true);
    state.config_message = 'Applied.';
    state.config_message_color = COLORS.success;
    state.scroll_to_bottom = true;
end

local function save_config()
    local tabs = normalize_tabs(config_editor_tabs());
    local path = config_file_path();
    local file, error_message = io.open(path, 'w');
    if (file == nil) then
        return false, tostring(error_message or 'open failed');
    end

    file:write(config_text_from_tabs(tabs));
    file:close();

    state.tabs = tabs;
    rebuild_tab_lookup();
    sync_config_editor_from_tabs(false);
    state.config_message = 'Saved.';
    state.config_message_color = COLORS.success;
    state.scroll_to_bottom = true;
    return true, ('Saved %s.'):fmt(path);
end

local function reset_config_editor_to_defaults()
    local used_keys = {};
    state.config_tabs = {};
    for index, tab in ipairs(DEFAULT_TABS) do
        table.insert(state.config_tabs, editor_from_tab(normalize_tab(tab, index, used_keys), index));
    end
    state.config_dirty = true;
    state.config_message = 'Reset pending.';
    state.config_message_color = COLORS.status;
end

local function mark_config_dirty()
    state.config_dirty = true;
    state.config_message = nil;
    state.config_message_color = nil;
end

function rebuild_tab_lookup()
    state.tab_by_key = {};
    for index, tab in ipairs(state.tabs) do
        tab.index = index;
        state.tab_by_key[tab.key] = tab;
    end

    if (state.tab_by_key[state.selected_tab] == nil and #state.tabs > 0) then
        state.selected_tab = state.tabs[1].key;
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

local function load_config()
    state.config_error = nil;
    package.loaded.ashitachat_config = nil;

    local ok, config = pcall(require, 'ashitachat_config');
    if (not ok) then
        state.config_error = tostring(config);
        state.tabs = normalize_tabs(DEFAULT_TABS);
    else
        state.tabs = normalize_tabs(configured_tabs(config));
    end

    rebuild_tab_lookup();
    sync_config_editor_from_tabs(false);
    state.scroll_to_bottom = true;
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

local function find_tab(value)
    local text = trim_string(value);
    if (text == '') then
        return nil;
    end

    local index = tonumber(text);
    if (index ~= nil and state.tabs[math.floor(index)] ~= nil) then
        return state.tabs[math.floor(index)];
    end

    local key = normalize_key(text, '');
    if (state.tab_by_key[key] ~= nil) then
        return state.tab_by_key[key];
    end

    local lower = text:lower();
    for _, tab in ipairs(state.tabs) do
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

local function normalized_search()
    return trim_string(state.search_buffer[1]):lower();
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

local function append_message(e)
    if (is_injected(e)) then
        return false;
    end

    local mode = chat_mode(e);
    local display_mode = chat_display_mode(e);
    if (mode == 150 or mode == 151 or mode == 152 or display_mode == 150 or display_mode == 151 or display_mode == 152) then
        return false;
    end

    local text = clean_message(e.message);
    if (text == '') then
        return false;
    end

    local category = classify_message(display_mode, text);
    local display = display_text(display_mode, text);

    state.message_seq = state.message_seq + 1;
    table.insert(state.messages, {
        id = state.message_seq,
        time = os.date('%H:%M:%S'),
        mode = mode,
        display_mode = display_mode,
        category = category,
        text = text,
        display = display,
        search_text = (display .. ' ' .. text):lower(),
        color = message_color(display_mode, category),
    });

    while (#state.messages > state.max_messages) do
        table.remove(state.messages, 1);
    end

    state.scroll_to_bottom = true;
    return true;
end

local function find_legacy_chat_windows()
    state.pointer_error = nil;
    state.win_ptr1 = nil;
    state.win_ptr2 = nil;

    local pattern = ashita.memory.find('FFXiMain.dll', 0, 'A1????????C64059018B0D????????C6415901C20800', 0, 0);
    if (pattern == nil or pattern == 0) then
        state.pointer_error = 'legacy chat window pattern not found';
        return false;
    end

    state.win_ptr1 = ashita.memory.read_uint32(pattern + 0x01);
    state.win_ptr2 = ashita.memory.read_uint32(pattern + 0x0B);

    if ((state.win_ptr1 == nil or state.win_ptr1 == 0) and (state.win_ptr2 == nil or state.win_ptr2 == 0)) then
        state.pointer_error = 'legacy chat window pointers were empty';
        return false;
    end

    return true;
end

local function pin_window_closed(pointer_address)
    if (pointer_address == nil or pointer_address == 0) then
        return false;
    end

    local window = ashita.memory.read_uint32(pointer_address);
    if (window == nil or window == 0) then
        return false;
    end

    ashita.memory.unprotect(window + 0x34, 4);
    ashita.memory.write_uint32(window + 0x34, 0x00);
    return true;
end

local function pin_legacy_chat_closed()
    if (state.hide_native ~= true) then
        return;
    end

    if (AshitaCore:GetChatManager():IsInputOpen() ~= 0x00) then
        return;
    end

    if (state.win_ptr1 == nil and state.win_ptr2 == nil and not find_legacy_chat_windows()) then
        return;
    end

    local pinned = false;
    pinned = pin_window_closed(state.win_ptr1) or pinned;
    pinned = pin_window_closed(state.win_ptr2) or pinned;

    if (pinned) then
        state.pin_count = state.pin_count + 1;
    end
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

local function render_tabs()
    for index, tab in ipairs(state.tabs) do
        if (index > 1) then
            imgui.SameLine(0, 2);
        end

        local active = state.selected_tab == tab.key;
        push_tab_style(active);
        if (imgui.Button(('%s##ashitachat_tab_%s'):fmt(tab.label, tab.key), { 98, 20 })) then
            state.selected_tab = tab.key;
            state.scroll_to_bottom = true;
        end
        pop_tab_style();
    end
end

local function render_search()
    local width = type(imgui.GetWindowWidth) == 'function' and imgui.GetWindowWidth() or 760;
    if (width >= 650) then
        imgui.SameLine(0, 14);
    end

    imgui.PushItemWidth(160);
    imgui.InputText('##ashitachat_search', state.search_buffer, 64);
    imgui.PopItemWidth();

    if (trim_string(state.search_buffer[1]) ~= '') then
        imgui.SameLine(0, 4);
        if (imgui.Button('x##ashitachat_search_clear', { 20, 20 })) then
            buffer_set(state.search_buffer, '');
            state.scroll_to_bottom = true;
        end
    end
end

local function begin_child(id, size, border)
    local child_open = false;
    local child_visible = true;

    if (type(imgui.BeginChild) == 'function' and type(imgui.EndChild) == 'function') then
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

local function render_message_list()
    local query = normalized_search();
    local selected_tab = state.tab_by_key[state.selected_tab] or state.tabs[1];
    local child_open, child_visible = begin_child('##ashitachat_message_list', { 0, -24 }, false);
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

        if (state.scroll_to_bottom and type(imgui.SetScrollHereY) == 'function') then
            imgui.SetScrollHereY(1.0);
        end
    end

    if (child_open) then
        imgui.EndChild();
    end

    state.scroll_to_bottom = false;
    return visible_count;
end

local function render_footer(visible_count)
    imgui.TextColored(COLORS.status, ('%d shown / %d buffered'):fmt(visible_count, #state.messages));
    imgui.SameLine(0, 10);
    imgui.TextColored(COLORS.status, state.hide_native and 'native hidden' or 'native visible');
    imgui.SameLine(0, 10);
    if (imgui.Button('v##ashitachat_scroll_bottom', { 22, 0 })) then
        state.scroll_to_bottom = true;
    end
    imgui.SameLine(0, 6);
    if (imgui.Button('cfg##ashitachat_open_config', { 34, 0 })) then
        state.config_visible[1] = true;
    end
end

local function render_chat_window()
    if (state.ui_visible[1] ~= true) then
        return;
    end

    local window_flags = bit.bor(IMGUI.window_no_title_bar, IMGUI.window_no_collapse);
    imgui.SetNextWindowPos({ 18, 528 }, IMGUI.cond_first_use);
    imgui.SetNextWindowSize({ 840, 310 }, IMGUI.cond_first_use);
    imgui.PushStyleVar(IMGUI.style_window_padding, { 6, 4 });
    imgui.PushStyleVar(IMGUI.style_window_border_size, 1.0);
    imgui.PushStyleVar(IMGUI.style_frame_padding, { 5, 2 });
    imgui.PushStyleColor(IMGUI.col_window_bg, COLORS.panel_bg);
    imgui.PushStyleColor(IMGUI.col_child_bg, COLORS.child_bg);
    imgui.PushStyleColor(IMGUI.col_border, COLORS.border);
    imgui.PushStyleColor(IMGUI.col_frame_bg, COLORS.frame);
    imgui.PushStyleColor(IMGUI.col_frame_bg_hovered, COLORS.frame_hover);

    if (imgui.Begin(('AshitaChat###AshitaChatWindow'), state.ui_visible, window_flags)) then
        if (type(imgui.SetWindowFontScale) == 'function') then
            imgui.SetWindowFontScale(state.font_scale);
        end

        render_tabs();
        render_search();
        imgui.Separator();
        local visible_count = render_message_list();
        render_footer(visible_count);
    end

    imgui.End();
    imgui.PopStyleColor(5);
    imgui.PopStyleVar(3);
end

local function add_config_tab()
    local index = #state.config_tabs + 1;
    table.insert(state.config_tabs, editor_from_tab({
        key = ('tab%d'):fmt(index),
        label = ('Tab %d'):fmt(index),
        filters = { 'general' },
        modes = {},
        contains = {},
    }, index));
    mark_config_dirty();
end

local function move_config_tab(index, offset)
    local target = index + offset;
    if (state.config_tabs[index] == nil or state.config_tabs[target] == nil) then
        return;
    end

    state.config_tabs[index], state.config_tabs[target] = state.config_tabs[target], state.config_tabs[index];
    mark_config_dirty();
end

local function remove_config_tab(index)
    if (#state.config_tabs <= 1 or state.config_tabs[index] == nil) then
        return;
    end

    table.remove(state.config_tabs, index);
    mark_config_dirty();
end

local function render_config_filter_checkbox(row, index, filter)
    local enabled = row.filters[filter] == true;
    if (imgui.Checkbox(('%s##ashitachat_config_tab_%d_filter_%s'):fmt(filter, index, filter), { enabled })) then
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

local function render_config_tab_editor(index, row)
    imgui.Separator();
    imgui.TextColored(COLORS.tab_text, ('Tab %d'):fmt(index));
    imgui.SameLine(0, 8);
    if (imgui.Button(('Up##ashitachat_config_tab_%d_up'):fmt(index), { 42, 0 })) then
        move_config_tab(index, -1);
        return;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Down##ashitachat_config_tab_%d_down'):fmt(index), { 54, 0 })) then
        move_config_tab(index, 1);
        return;
    end
    imgui.SameLine(0, 4);
    if (imgui.Button(('Remove##ashitachat_config_tab_%d_remove'):fmt(index), { 70, 0 })) then
        remove_config_tab(index);
        return;
    end

    imgui.PushItemWidth(160);
    if (imgui.InputText(('Key##ashitachat_config_tab_%d_key'):fmt(index), row.key_buffer, 32)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.SameLine(0, 12);
    imgui.PushItemWidth(220);
    if (imgui.InputText(('Label##ashitachat_config_tab_%d_label'):fmt(index), row.label_buffer, 48)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();

    imgui.TextColored(COLORS.status, 'Filters');
    for filter_index, filter in ipairs(FILTER_ORDER) do
        if (filter_index > 1) then
            imgui.SameLine(0, 8);
        end
        render_config_filter_checkbox(row, index, filter);
    end

    imgui.PushItemWidth(520);
    if (imgui.InputText(('Modes##ashitachat_config_tab_%d_modes'):fmt(index), row.modes_buffer, 128)) then
        mark_config_dirty();
    end
    if (imgui.InputText(('Contains##ashitachat_config_tab_%d_contains'):fmt(index), row.contains_buffer, 256)) then
        mark_config_dirty();
    end
    imgui.PopItemWidth();
end

local function render_config_window()
    if (state.config_visible[1] ~= true) then
        return;
    end

    imgui.SetNextWindowSize({ 720, 520 }, IMGUI.cond_first_use);
    local flags = bit.bor(IMGUI.window_no_collapse, IMGUI.window_always_auto_resize);
    if (imgui.Begin('AshitaChat Configuration###AshitaChatConfig', state.config_visible, flags)) then
        if (imgui.Button('Add Tab##ashitachat_config_add_tab')) then
            add_config_tab();
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

        local child_open, child_visible = begin_child('##ashitachat_config_tab_list', { 0, 420 }, true);
        if (child_visible) then
            for index, row in ipairs(state.config_tabs) do
                render_config_tab_editor(index, row);
            end
        end
        if (child_open) then
            imgui.EndChild();
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

local function set_hidden(hidden)
    state.hide_native = hidden == true;

    if (state.hide_native) then
        state.ui_visible[1] = true;
        find_legacy_chat_windows();
        if (state.pointer_error ~= nil) then
            log_warn('Native chat lines are blocked, but legacy chat window pinning is unavailable: ' .. state.pointer_error .. '.');
        else
            log_warn('Native chat lines are blocked and legacy chat windows are pinned closed. Use /ashitachat show to restore.');
        end
    else
        log_info('Native chat lines are visible.');
    end
end

local function print_tabs()
    for _, tab in ipairs(state.tabs) do
        log_info(('%d. %s (%s): %s'):fmt(tab.index, tab.label, tab.key, filters_summary(tab)));
    end
end

local function print_help()
    log_info('Commands:');
    log_info('/ashitachat hide - Block non-injected incoming chat lines from the native log.');
    log_info('/ashitachat show - Stop blocking native chat lines.');
    log_info('/ashitachat toggle - Toggle native chat-line blocking.');
    log_info('/ashitachat ui - Toggle the replacement chat window.');
    log_info('/ashitachat config - Toggle the in-game tab configuration window.');
    log_info('/ashitachat clear - Clear the replacement chat buffer.');
    log_info('/ashitachat tab <key|number> - Switch replacement chat tabs.');
    log_info('/ashitachat tabs - List configured replacement chat tabs.');
    log_info('/ashitachat reload - Reload ashitachat_config.lua.');
    log_info('/ashitachat status - Show trial status, pin count, and blocked-line count.');
end

local function print_status()
    log_info(string.format(
        'Status: nativeChat=%s, overlay=%s, tab=%s, tabs=%d, config=%s, bufferedLines=%d, blockedLines=%d, pins=%d, pointers=%s, modes=%s.',
        state.hide_native and 'hidden' or 'visible',
        state.ui_visible[1] and 'visible' or 'hidden',
        state.selected_tab,
        #state.tabs,
        state.config_error == nil and 'ready' or 'defaulted',
        #state.messages,
        state.blocked_count,
        state.pin_count,
        state.pointer_error or 'ready',
        mode_summary()));
end

ashita.events.register('load', 'load_cb', function ()
    load_config();
    log_info('Loaded. Replacement chat window is visible; native chat is visible until /ashitachat hide is used.');
    if (state.config_error ~= nil) then
        log_warn('Using default tab config because ashitachat_config.lua did not load: ' .. state.config_error);
    end
end);

ashita.events.register('unload', 'unload_cb', function ()
    state.hide_native = false;
    state.ui_visible[1] = false;
    state.config_visible[1] = false;
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    pin_legacy_chat_closed();
    render_chat_window();
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
    elseif (action == 'ui' or action == 'window') then
        state.ui_visible[1] = not state.ui_visible[1];
        log_info('Replacement chat window is now ' .. (state.ui_visible[1] and 'visible.' or 'hidden.'));
    elseif (action == 'config' or action == 'settings') then
        state.config_visible[1] = not state.config_visible[1];
        log_info('Configuration window is now ' .. (state.config_visible[1] and 'visible.' or 'hidden.'));
    elseif (action == 'clear') then
        state.messages = {};
        state.scroll_to_bottom = true;
        log_info('Replacement chat buffer cleared.');
    elseif (action == 'tab') then
        local tab = find_tab(args[3]);
        if (tab == nil) then
            log_warn('Unknown tab. Use /ashitachat tabs to list configured tabs.');
        else
            state.selected_tab = tab.key;
            state.scroll_to_bottom = true;
            log_info('Replacement chat tab set to ' .. tab.label .. '.');
        end
    elseif (action == 'tabs') then
        print_tabs();
    elseif (action == 'reload') then
        load_config();
        log_info(('Reloaded %d configured replacement chat tabs.'):fmt(#state.tabs));
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
    if (mode == 150 or mode == 151 or mode == 152) then
        return;
    end

    append_message(e);

    if (state.hide_native ~= true) then
        return;
    end

    if (not is_injected(e)) then
        state.blocked_count = state.blocked_count + 1;
        state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1;
        e.blocked = true;
    end
end);
