# Quirks

Machine-specific facts, workarounds, and places where tools lie. Each note
carries its evidence. Newest at the top.

- (2026-10-21) Maya 2027.2 crashes when its own Qt Open dialog is accepted,
  three launches, three hangs. Open scenes via commandPort `scene.open`, or
  have the user open them by hand; then confirm `scene_info.file_path`.
  Evidence: `~/Documents/maya/GG_MayaMCP-issues.md`, sampled crash stacks.
- (2026-10-21) Maya `health_check` reports `offline` on the first call of a
  session even while every other tool works. Call `maya_connect` first or run
  `~/.config/opencode/bin/maya-status.sh` instead of trusting it.
- (2026-10-21) Maya can't bind port 7001 while a previous instance is still
  shutting down (`EADDRINUSE`). `userSetup.py` retries for 120s in the
  background, so poll the port up to two minutes before declaring Maya broken.
- (2026-08) Editing `userSetup.py` triggers a "Secure UserSetup Checksum
  verification" dialog on next launch that blocks quitting. Answer Yes via
  `peekaboo.inspect_ui` on the Maya app, not by blind coordinate clicks.
- (2026-08) Peekaboo 4.5.0 `type` can exit 1 while the text landed. Observe
  (fresh `see`) before retrying; a blind retry types the string twice.
- (2026-08) `~/.config/opencode/opencode.json` is re-read on every save. Edit
  with jq/python3 to a temp file then `mv` into place; a bad save takes the
  whole MCP layer down for all sessions.
