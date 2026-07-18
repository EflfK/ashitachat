return {
    tabs = {
        -- Reorder tabs by moving these entries. Add more entries with the same
        -- shape to create new tabs.
        { key = 'general', label = 'General', filters = { 'all' } },
        { key = 'combat', label = 'Combat Log', filters = { 'combat' } },
        { key = 'group', label = 'Group', filters = { 'group' } },
        { key = 'lfg', label = 'LFG', filters = { 'lfg' } },

        -- Optional matching forms:
        -- { key = 'shout', label = 'Shout', modes = { 2, 3, 10, 11 } },
        -- { key = 'sales', label = 'Sales', contains = { 'wts', 'wtb', 'sell?' } },
        -- { key = 'social', label = 'Social', filters = { 'general', 'group' } },
    },
};
