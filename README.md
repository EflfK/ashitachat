# ashitachat

Experimental Ashita v4 chat UI addon for CatsEyeXI.

Initial scope:

- Keep behavior local to the client UI.
- Do not send gameplay commands, automate actions, or inject packets.
- Provide a replacement chat window that can run alongside, then replace, the
  native chat log.

## Current Trial

This version renders draggable, resizable ImGui replacement chat windows with
configurable chrome and background opacity. It can stay close to the native FFXI
chat log with a translucent panel, tabs, search, and footer controls, or render
as floating chat text with no visible bars or panel. It starts with one Main
window containing six tabs:

- General: local/direct communication (NPC dialogue, say, tell, party, emote,
  and assist), plus fishing activity and skill-gain notices, excluding shout,
  yell, linkshell, Linkshell 2, and Unity/global traffic. Fishing activity
  includes bites, gut-feeling and skill warnings, catches (including monsters
  and chests), failures, line or rod breaks, give-up messages, common fishing
  setup errors, keen-angler/epic notices, and goldfish-scooping activity.
- Whisper: all incoming and outgoing tell messages.
- Combat Log: battle, casting, damage, and status-effect style lines.
- Group: party and tell lines.
- LFG: lines that look like party finder, recruiting, LFG, or LFM traffic.
- System: addon and system-status lines.

Each window includes its own tab selection, search field, footer controls, and
scroll state over the same bounded local chat buffer when those controls are
enabled. It is passive UI: it only captures
non-injected incoming chat text and renders it locally. Say, shout, yell, tell,
party, linkshell, assist, emote, system, and combat-style lines are colored from
the closest known native chat mode colors. Injected addon/status output is left
out of the replacement buffer so verbose addon configuration or status lines do
not flood the chat tabs.

Windows and tabs can be configured in game with `/ashitachat config`. The
configuration window can add, remove, rename, reorder, apply, and save window
definitions. Each configured chat window has its own configuration tab, and the
selected window editor manages that window's chat tabs. Save writes
`Ashita/config/addons/ashitachat/ashitachat_config.lua`, outside the addon
folder, and render order is the order of entries in that file:

Incoming tells automatically open a temporary conversation tab named for the
sender in the first chat window. Replies to that player are routed into the
same tab, keeping each tell conversation separate. Conversation tabs remain
visible even when the window's normal tab bar is hidden, and each has an `x`
button that closes the tab without deleting its messages from the bounded chat
buffer. A later incoming tell from that player opens the tab again.

```lua
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
            tabs_on_bottom = false,
            show_search = false,
            show_footer = false,
            show_border = false,
            show_scrollbar = false,
            background_opacity = 0.00,
            tabs = {
                { key = 'general', label = 'General', filters = { 'progress', 'auction', 'mission' }, modes = { 1, 4, 5, 8, 9, 12, 13, 150, 151, 152, 210, 220, 222 } },
                { key = 'whisper', label = 'Whisper', modes = { 4, 12 } },
                { key = 'combat', label = 'Combat Log', filters = { 'combat' } },
                { key = 'group', label = 'Group', filters = { 'group' } },
                { key = 'lfg', label = 'LFG', filters = { 'lfg' } },
            },
        },
    },
}
```

Each window can contain multiple tabs. Each tab can use `filters`, `modes`,
`contains`, and/or `excludes`. Valid filters are `all`, `general`, `combat`,
`group`, `lfg`, `progress` for fishing activity and skill-gain notices,
`auction` for successful and unsuccessful Auction House purchase notices, and
`mission` for accepted, completed, failed, or abandoned mission and quest
notices. Tabs keyed `general` or the legacy `default` always receive `progress`,
`auction`, and `mission`, so existing saved default configs gain these notices
automatically. `modes`
matches exact Ashita chat modes; the in-game config exposes
common mode groups as checkboxes and keeps a raw comma-separated `Mode IDs`
field for exact/custom IDs. `contains` matches case-insensitive text fragments.
`excludes` rejects matching case-insensitive fragments after the inclusion rules,
so a broad tab can omit noisy addon notices while an `all` tab still retains them.
The common mode checkboxes include `NPC`, which matches native NPC dialog modes
150-152. Ashita's mode-190 legacy-chat reinjections are intentionally ignored
so NPC dialog appears once. Legacy configs with top-level `tabs = { ... }`
still load as a single Main window.

Each window can also set `show_tabs`, `tabs_on_bottom`, `show_search`,
`show_footer`, `show_border`, `show_scrollbar`, and `background_opacity`.
Set `tabs_on_bottom = true` to keep the message list above a bottom-edge tab
strip. Use
`show_tabs = false`, `show_search = false`, `show_footer = false`,
`show_border = false`, `show_scrollbar = false`, and
`background_opacity = 0.00` for floating text with no visible chat chrome.
When the mouse enters a chat window, its background fades to at least 78%
opacity over 0.30 seconds so the text and controls are easier to read and use.
It fades back to the configured opacity over 0.45 seconds after the mouse
leaves, matching AshitaMiniMap's hover behavior.
The loader also accepts negative aliases such as `hide_tabs = true` and
`hide_search = true` for hand-written configs.

Each window also stores `window_x`, `window_y`, `window_width`, and
`window_height`. Move or resize the chat window, then click `Save` in
`/ashitachat config` to persist its placement in the config folder outside the
addon install.

When a native task-focused menu activates the temporary centered chat layout,
each chat window eases its position and size over a short, non-overshooting
transition. Closing or changing the menu mid-motion redirects the window from
its current geometry, and manual movement remains immediate in the normal
layout.

AshitaChat also saves the most recent 100 captured lines when the addon unloads
and restores them on its next load. The bounded history lives at
`Ashita/config/addons/ashitachat/ashitachat_history.lua`, so addon reloads and
reinstalls retain a short scrollback without adding per-message disk writes.

The addon can also suppress native chat-log lines while leaving the legacy UI
windows available for chat input, NPC choices, Home Point destinations, and
other interactive menus.

The addon registers the Ashita v4 `text_in` event. When hiding is enabled, it
blocks non-injected incoming text by setting `e.blocked = true`, except for
native NPC dialog modes 150-152. Those modes must continue through FFXI's
native event UI so choice menus such as Home Point destinations and Unity
selection remain interactive. Their live payloads also bypass auto-translate
parsing so encoded choice text is not altered before the native menu consumes
it. Injected lines are left visible so addon status messages can still be seen.
FFXI's mode-190 legacy render copies of NPC dialog are blocked, preventing the
native chat box from filling with duplicate cutscene text without interfering
with the event itself.

It intentionally does not write to the legacy chat-window memory structures.
Pinning those structures closed also suppresses unrelated interactive menus and
breaks the normal `F` chat expansion behavior. Native lines are hidden only by
blocking their local `text_in` rendering after they have been captured for the
replacement windows; original NPC event dialog remains available to FFXI's
native event processing for compatibility. The mode-190 legacy copy is
suppressed, so this compatibility path does not populate the large native chat
log.

## Install

From this repository:

```powershell
.\install.ps1
```

The installer does not overwrite saved config under
`Ashita/config/addons/ashitachat/`. If it finds an older installed
`addons/ashitachat/ashitachat_config.lua` and no saved config exists yet, it
migrates that file before replacing the addon folder.

Or pass a custom Ashita root:

```powershell
.\install.ps1 -AshitaRoot "C:\Path\To\Ashita"
```

Then load in game:

```text
/addon load ashitachat
```

The addon suppresses native chat lines as soon as it loads while preserving the
legacy UI window state needed by menus and input. Use `/ashitachat show` if you
want to restore native chat lines while keeping the replacement addon loaded.

The installer also adds `/addon load ashitachat` followed by `/ashitachat hide`
to `Ashita\scripts\default.txt` by default. The hide command is retained for
compatibility with existing installs and is harmless now that hiding happens
during addon load. Pass `-SkipAutoload` to copy the addon without changing the
startup script.

## Commands

```text
/ashitachat hide
/ashitachat show
/ashitachat toggle
/ashitachat ui
/ashitachat window main toggle
/ashitachat config
/ashitachat clear
/ashitachat tab general
/ashitachat tab whisper
/ashitachat tab combat main
/ashitachat tab combat
/ashitachat tab group
/ashitachat tab lfg
/ashitachat tabs
/ashitachat windows
/ashitachat reload
/ashitachat status
/ashitachat help
```

`/achat` is also accepted as a short alias.

## Validation

```powershell
.\scripts\validate.ps1
```

