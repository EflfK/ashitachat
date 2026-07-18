addon.name = 'ashitachat';
addon.author = 'EflfK';
addon.version = '0.1.0';
addon.desc = 'Experimental local chat UI replacement trial for Ashita v4.';

require('common');

local chat = require('chat');

local state = {
    hide_native = false,
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
    log_info('/ashitachat status - Show trial status, pin count, and blocked-line count.');
end

local function print_status()
    log_info(string.format(
        'Status: nativeChat=%s, blockedLines=%d, pins=%d, pointers=%s, modes=%s.',
        state.hide_native and 'hidden' or 'visible',
        state.blocked_count,
        state.pin_count,
        state.pointer_error or 'ready',
        mode_summary()));
end

ashita.events.register('load', 'load_cb', function ()
    log_info('Loaded. Native chat is visible until /ashitachat hide is used.');
end);

ashita.events.register('unload', 'unload_cb', function ()
    state.hide_native = false;
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    pin_legacy_chat_closed();
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
    elseif (action == 'status') then
        print_status();
    elseif (action == 'help') then
        print_help();
    else
        log_warn('Unknown command. Use /ashitachat help.');
    end
end);

ashita.events.register('text_in', 'text_in_cb', function (e)
    if (state.hide_native ~= true) then
        return;
    end

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

    if (not is_injected(e)) then
        state.blocked_count = state.blocked_count + 1;
        state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1;
        e.blocked = true;
    end
end);
