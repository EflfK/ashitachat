return {
    windows = {
        {
            key = 'main',
            label = 'Main',
            visible = true,
            window_x = 18,
            window_y = 528,
            window_width = 840,
            window_height = 310,
            show_tabs = false,
            show_search = false,
            show_footer = false,
            show_border = false,
            show_scrollbar = false,
            background_opacity = 0.00,
            tabs = {
                -- Reorder tabs by moving these entries. Add more entries with
                -- the same shape to create new tabs in this window.
                { key = 'general', label = 'General', filters = { 'all' } },
                { key = 'combat', label = 'Combat Log', filters = { 'combat' } },
                { key = 'group', label = 'Group', filters = { 'group' } },
                { key = 'lfg', label = 'LFG', filters = { 'lfg' } },

                -- Optional matching forms:
                -- { key = 'shout', label = 'Shout', modes = { 2, 3, 10, 11 } },
                -- { key = 'sales', label = 'Sales', contains = { 'wts', 'wtb', 'sell?' } },
                -- { key = 'social', label = 'Social', filters = { 'general', 'group' } },
            },
        },
    },
};
