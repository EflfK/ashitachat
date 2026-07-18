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
};

local COLORS = {
    panel_bg = { 0.015, 0.012, 0.010, 0.88 },
    child_bg = { 0.000, 0.000, 0.000, 0.72 },
    border = { 0.55, 0.36, 0.18, 0.95 },
    tab = { 0.070, 0.050, 0.045, 0.96 },
    tab_hover = { 0.145, 0.085, 0.050, 0.98 },
    tab_active = { 0.240, 0.125, 0.045, 1.00 },
    frame = { 0.030, 0.030, 0.030, 0.92 },
    frame_hover = { 0.080, 0.065, 0.045, 0.96 },
    tab_text = { 0.98, 0.72, 0.22, 1.00 },
    timestamp = { 0.63, 0.64, 0.68, 1.00 },
    general = { 0.82, 0.68, 1.00, 1.00 },
    combat = { 1.00, 0.76, 0.46, 1.00 },
    group = { 0.42, 0.86, 1.00, 1.00 },
    lfg = { 1.00, 0.93, 0.12, 1.00 },
    status = { 0.72, 0.72, 0.76, 1.00 },
    empty = { 0.48, 0.48, 0.52, 1.00 },
};

local TABS = {
    { key = 'general', label = 'General' },
    { key = 'combat', label = 'Combat Log' },
    { key = 'group', label = 'Group' },
    { key = 'lfg', label = 'LFG' },
};

local TAB_BY_KEY = {};
for _, tab in ipairs(TABS) do
    TAB_BY_KEY[tab.key] = tab;
end

local MODE_LABELS = {
    [1] = 'say',
    [2] = 'shout',
    [3] = 'shout',
    [4] = 'tell',
    [5] = 'party',
    [6] = 'linkshell',
    [8] = 'emote',
    [10] = 'yell',
    [11] = 'yell',
    [12] = 'tell',
    [13] = 'party',
    [14] = 'linkshell',
    [205] = 'linkshell',
    [210] = 'party',
    [213] = 'linkshell2',
    [214] = 'linkshell2',
    [217] = 'linkshell2',
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
    selected_tab = 'general',
    search_buffer = T{ '' },
    messages = {},
    message_seq = 0,
    max_messages = 300,
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
    local label = MODE_LABELS[mode];
    if (label == nil or text:find('^%[') ~= nil or text:find('^%(') ~= nil) then
        return text;
    end

    return ('[%s] %s'):fmt(label, text);
end

local function category_color(category)
    return COLORS[category] or COLORS.general;
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

local function message_matches_tab(message, tab_key)
    if (tab_key == 'general') then
        return true;
    end

    return message.category == tab_key;
end

local function append_message(e)
    local mode = chat_mode(e);
    if (mode == 150 or mode == 151 or mode == 152) then
        return false;
    end

    local text = clean_message(e.message);
    if (text == '') then
        return false;
    end

    local category = classify_message(mode, text);
    local display = display_text(mode, text);

    state.message_seq = state.message_seq + 1;
    table.insert(state.messages, {
        id = state.message_seq,
        time = os.date('%H:%M:%S'),
        mode = mode,
        category = category,
        text = text,
        display = display,
        search_text = (display .. ' ' .. text):lower(),
        color = category_color(category),
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
    imgui.PushStyleColor(IMGUI.col_button_hovered, active and COLORS.tab_active or COLORS.tab_hover);
    imgui.PushStyleColor(IMGUI.col_button_active, COLORS.tab_active);
    imgui.PushStyleColor(IMGUI.col_text, COLORS.tab_text);
end

local function pop_tab_style()
    imgui.PopStyleColor(4);
end

local function render_tabs()
    for index, tab in ipairs(TABS) do
        if (index > 1) then
            imgui.SameLine(0, 4);
        end

        local active = state.selected_tab == tab.key;
        push_tab_style(active);
        if (imgui.Button(('%s##ashitachat_tab_%s'):fmt(tab.label, tab.key), { 104, 24 })) then
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

    imgui.PushItemWidth(170);
    imgui.InputText('##ashitachat_search', state.search_buffer, 64);
    imgui.PopItemWidth();

    if (trim_string(state.search_buffer[1]) ~= '') then
        imgui.SameLine(0, 4);
        if (imgui.Button('x##ashitachat_search_clear', { 22, 22 })) then
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
    local selected_tab = TAB_BY_KEY[state.selected_tab] ~= nil and state.selected_tab or 'general';
    local child_open, child_visible = begin_child('##ashitachat_message_list', { 0, -26 }, true);
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
    imgui.SameLine(0, 12);
    imgui.TextColored(COLORS.status, state.hide_native and 'native hidden' or 'native visible');
    imgui.SameLine(0, 12);
    if (imgui.Button('v##ashitachat_scroll_bottom', { 24, 0 })) then
        state.scroll_to_bottom = true;
    end
end

local function render_chat_window()
    if (state.ui_visible[1] ~= true) then
        return;
    end

    local window_flags = bit.bor(IMGUI.window_no_title_bar, IMGUI.window_no_collapse);
    imgui.SetNextWindowPos({ 18, 520 }, IMGUI.cond_first_use);
    imgui.SetNextWindowSize({ 760, 310 }, IMGUI.cond_first_use);
    imgui.PushStyleVar(IMGUI.style_window_padding, { 6, 5 });
    imgui.PushStyleVar(IMGUI.style_window_border_size, 1.0);
    imgui.PushStyleVar(IMGUI.style_frame_padding, { 7, 4 });
    imgui.PushStyleColor(IMGUI.col_window_bg, COLORS.panel_bg);
    imgui.PushStyleColor(IMGUI.col_child_bg, COLORS.child_bg);
    imgui.PushStyleColor(IMGUI.col_border, COLORS.border);
    imgui.PushStyleColor(IMGUI.col_frame_bg, COLORS.frame);
    imgui.PushStyleColor(IMGUI.col_frame_bg_hovered, COLORS.frame_hover);

    if (imgui.Begin(('AshitaChat###AshitaChatWindow'), state.ui_visible, window_flags)) then
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

local function print_help()
    log_info('Commands:');
    log_info('/ashitachat hide - Block non-injected incoming chat lines from the native log.');
    log_info('/ashitachat show - Stop blocking native chat lines.');
    log_info('/ashitachat toggle - Toggle native chat-line blocking.');
    log_info('/ashitachat ui - Toggle the replacement chat window.');
    log_info('/ashitachat clear - Clear the replacement chat buffer.');
    log_info('/ashitachat tab <general|combat|group|lfg> - Switch replacement chat tabs.');
    log_info('/ashitachat status - Show trial status, pin count, and blocked-line count.');
end

local function print_status()
    log_info(string.format(
        'Status: nativeChat=%s, overlay=%s, tab=%s, bufferedLines=%d, blockedLines=%d, pins=%d, pointers=%s, modes=%s.',
        state.hide_native and 'hidden' or 'visible',
        state.ui_visible[1] and 'visible' or 'hidden',
        state.selected_tab,
        #state.messages,
        state.blocked_count,
        state.pin_count,
        state.pointer_error or 'ready',
        mode_summary()));
end

ashita.events.register('load', 'load_cb', function ()
    log_info('Loaded. Replacement chat window is visible; native chat is visible until /ashitachat hide is used.');
end);

ashita.events.register('unload', 'unload_cb', function ()
    state.hide_native = false;
    state.ui_visible[1] = false;
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    pin_legacy_chat_closed();
    render_chat_window();
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
    elseif (action == 'clear') then
        state.messages = {};
        state.scroll_to_bottom = true;
        log_info('Replacement chat buffer cleared.');
    elseif (action == 'tab') then
        local tab = args[3] and args[3]:lower() or '';
        if (TAB_BY_KEY[tab] == nil) then
            log_warn('Unknown tab. Use general, combat, group, or lfg.');
        else
            state.selected_tab = tab;
            state.scroll_to_bottom = true;
            log_info('Replacement chat tab set to ' .. tab .. '.');
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
