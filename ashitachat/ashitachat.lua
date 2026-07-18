addon.name = 'ashitachat';
addon.author = 'EflfK';
addon.version = '0.1.0';
addon.desc = 'Experimental local chat UI replacement trial for Ashita v4.';

require('common');

local chat = require('chat');

local state = {
    hide_native = false,
    blocked_count = 0,
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
        log_warn('Native non-injected chat lines are hidden. Use /ashitachat show to restore them.');
    else
        log_info('Native chat lines are visible.');
    end
end

local function print_help()
    log_info('Commands:');
    log_info('/ashitachat hide - Block non-injected incoming chat lines from the native log.');
    log_info('/ashitachat show - Stop blocking native chat lines.');
    log_info('/ashitachat toggle - Toggle native chat-line blocking.');
    log_info('/ashitachat status - Show trial status and blocked-line count.');
end

local function print_status()
    log_info(string.format(
        'Status: nativeChat=%s, blockedLines=%d, modes=%s.',
        state.hide_native and 'hidden' or 'visible',
        state.blocked_count,
        mode_summary()));
end

ashita.events.register('load', 'load_cb', function ()
    log_info('Loaded. Native chat is visible until /ashitachat hide is used.');
end);

ashita.events.register('unload', 'unload_cb', function ()
    state.hide_native = false;
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

    if (not is_injected(e)) then
        local mode = tonumber(e.mode) or -1;
        state.blocked_count = state.blocked_count + 1;
        state.mode_counts[mode] = (state.mode_counts[mode] or 0) + 1;
        e.blocked = true;
    end
end);
