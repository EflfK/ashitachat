# ashitachat

Experimental Ashita v4 chat UI addon for CatsEyeXI.

Initial scope:

- Keep behavior local to the client UI.
- Do not send gameplay commands, automate actions, or inject packets.
- Start with a reversible trial for suppressing native chat-log lines.

## Current Trial

This first version tests whether Ashita can suppress native chat-log lines and
pin the legacy chat windows closed while chat input is not open.

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
/ashitachat status
/ashitachat help
```

`/achat` is also accepted as a short alias.

## Validation

```powershell
.\scripts\validate.ps1
```

