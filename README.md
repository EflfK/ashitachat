# ashitachat

Experimental Ashita v4 chat UI addon for CatsEyeXI.

Initial scope:

- Keep behavior local to the client UI.
- Do not send gameplay commands, automate actions, or inject packets.
- Provide a replacement chat window that can run alongside, then replace, the
  native chat log.

## Current Trial

This version renders a draggable, resizable ImGui replacement chat window with
four tabs:

- General: all captured chat lines.
- Combat Log: battle, casting, damage, and status-effect style lines.
- Group: party and tell lines.
- LFG: lines that look like party finder, recruiting, LFG, or LFM traffic.

The window includes a search field and a bounded local buffer. It is passive UI:
it only captures non-injected incoming chat text and renders it locally. Injected
addon/status output is left out of the replacement buffer so verbose addon
configuration/status lines do not flood the chat tabs.

Tabs can be configured in game with `/ashitachat config`. The configuration
window can add, remove, rename, reorder, apply, and save tab definitions. Save
writes `ashitachat/ashitachat_config.lua`, and tab order is the order of entries
in that file:

```lua
return {
    tabs = {
        { key = 'general', label = 'General', filters = { 'all' } },
        { key = 'combat', label = 'Combat Log', filters = { 'combat' } },
        { key = 'group', label = 'Group', filters = { 'group' } },
        { key = 'lfg', label = 'LFG', filters = { 'lfg' } },
    },
}
```

Each tab can use `filters`, `modes`, and/or `contains`. Valid filters are
`all`, `general`, `combat`, `group`, and `lfg`. `modes` matches exact Ashita
chat modes. `contains` matches case-insensitive text fragments.

The addon can also suppress native chat-log lines and pin the legacy chat
windows closed while chat input is not open.

The addon registers the Ashita v4 `text_in` event. When hiding is enabled, it
blocks non-injected incoming text by setting `e.blocked = true`. Injected lines
are left visible so addon status messages can still be seen.

It also uses the same legacy-chat window field that FancyChat writes while its
replacement window is active. This is a local UI-only memory write that keeps
the legacy chat windows closed; it is skipped while the normal chat input is
open so the user can still type `/ashitachat show`.

## Install

From this repository:

```powershell
.\install.ps1
```

Or pass a custom Ashita root:

```powershell
.\install.ps1 -AshitaRoot "C:\Path\To\Ashita"
```

Then load in game:

```text
/addon load ashitachat
```

## Commands

```text
/ashitachat hide
/ashitachat show
/ashitachat toggle
/ashitachat ui
/ashitachat config
/ashitachat clear
/ashitachat tab general
/ashitachat tab combat
/ashitachat tab group
/ashitachat tab lfg
/ashitachat tabs
/ashitachat reload
/ashitachat status
/ashitachat help
```

`/achat` is also accepted as a short alias.

## Validation

```powershell
.\scripts\validate.ps1
```

