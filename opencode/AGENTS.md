# Personal Preferences (Global)

## Language

- Never use `any` unless 100% necessary or specifically instructed.
- TypeScript strict mode; prefer inferred types over annotations. `any` is the enemy.

## Commands

- Don't run dev servers — assume they're running.
- Don't run build commands unless specifically told to.
- Focus on check commands: `bun run typecheck`, `bun run lint`, `tsc --noEmit`, `cargo check`, `go vet ./...`

## Package Managers

- Use pnpm if the project already uses it, otherwise use bun.
- Never use npm or yarn.

## Tech Stack Defaults

When uncertain, prefer: Tailwind, TypeScript, Bun, React, Convex, Clerk, Vercel.
(Replace with _your_ actual defaults — this is just a starting template)

## Code Style

- Always strive for concise, simple solutions.
- If a problem can be solved in a simpler way, propose it.
- Explicit > implicit. Immutable patterns where practical.
- Minimize dependencies — every package is a liability.
- Complexity belongs at the adapter boundary. Orchestration stays pure, UI stays dumb.

## General

- If asked to do too much work at once, stop and state that clearly.
- For computer-use verification: shell out to external tool if helpful.
- If a rule here fights the task in front of you, say so loudly and get a human sign-off before breaking it.

## Shared Config Files

`~/.config/opencode/opencode.json` is read by every session on this machine, and opencode re-reads
it on each write. Each intermediate save is live for all of them, so a 90 second mistake takes the
whole MCP layer down at once.

- Edit JSON with a JSON tool: `jq` for one value, `python3 -c` with `json.load` / `json.dump` for
  structure. Write to a temp file and `mv` it into place, so no reader sees a partial document.
- Reach for `sed` on JSON with the specific failure in mind: `sed -i '' 's/,$//'` on a 500 line
  config strips a comma from every line, leaving a file that parses as neither JSON nor JSONC.
- Validate and inspect before calling it done: `python3 -m json.tool <file>`, then `git diff` in
  `~/.config` (dotfiles repo) to see exactly what moved.

## Mac Control

Three MCPs give this machine full desktop and Maya control. Use them; do not
rebuild equivalents. Peekaboo covers the desktop, `computer-use` adds real
desktop input with vision and the accessibility tree, and maya-mcp covers Maya.

### peekaboo (desktop GUI automation)

Screenshot, click, type, scroll, drag, hotkeys, and the accessibility tree.
Peekaboo reads the accessibility tree, so it hands back element IDs rather than
coordinates. Observe first, then act on the IDs it returns. Never guess
coordinates from a screenshot when an element ID exists.

The 24 MCP tools: `action`, `agent`, `analyze`, `app`, `browser`, `capture`,
`click`, `clipboard`, `dialog`, `dock`, `image`, `inspect_ui`, `menu`, `paste`,
`permissions`, `press`, `scroll`, `see`, `set_value`, `sleep`, `space`, `type`,
`verify_state`, `window`.

- Observe with `see` or `inspect_ui` (both return element IDs), `image` for a
  plain screenshot, `verify_state` to assert an expected UI state afterwards.
  CLI subcommands use hyphens (`set-value`, `verify-state`); MCP names are
  underscored. Note `peekaboo image` was **removed in v4** on the CLI, use
  `peekaboo see --no-elements`.
- `action` (CLI: `peekaboo action`) invokes a named accessibility action such as
  `AXPress`. `set_value` writes a settable accessibility value directly.
- **The MCP schemas do not match the CLI flags.** Over MCP, `see` takes
  `app_target` rather than `app`, and `type` takes only a `snapshot` plus the
  text, because the snapshot already determines the target. There is no `app`
  or `window_id` on the MCP `type` tool. Check `tools/list` before assuming a
  flag carries over.
- `click`/`type` default to **background** delivery when a target is
  `--app`/`--pid`/`--window-id` is resolvable, so the app does not steal focus
  from the user. Cold launches and ambiguous targets need `--foreground`.
- Peekaboo refuses to act when it cannot attest an exact target, and says why.
  That refusal is a feature. Read the refusal, observe again, disambiguate by
  window-id. Do not retry the same ambiguous call in a loop.

#### Known Peekaboo 4.5.0 bugs that bite this workflow

These are unfixed upstream in 4.5.0 and the project cannot be rebuilt on this
machine (no full Xcode). Work around them. Do not report them as tool failures.

**`type` can report failure when it actually succeeded. Never blind-retry it.**
A plain `type --app X --window-id N` exits 1 with "Typing did not return an
accepted outcome", or "Action outcome is indeterminate / Typing failed after
foreground setup may have changed focus", while the text is in fact present.
That is a false negative, not a failure. Its own hint ("observe the target
before retrying") is right: **observe before retrying.** Run `see` on the window
and check for your marker string. If it is there, the type worked. Retrying
without checking is how you end up with the string typed twice.

Prefer the form that does report correctly: `--snapshot "$SNAP"` together with
`--clear` returns "Typing confirmed" and exit 0. Over MCP, `type` already
requires a `snapshot` and nothing else, so the snapshot fully determines the
target and the MCP path is safer than the bare CLI. Verified over MCP: `see`
with `app_target` then `type` with that snapshot returns `isError: false` and
"[ok] Cleared field, Typed: ..." with the text present in the tree.

House style for the rest of the tool is exit 0 plus "dispatched but not
verified". Only the typing path hard-fails. `press` and `click` degrade
correctly.

**Element IDs are snapshot-scoped and must never be reused.** `elem_N` is
positional, so any tree change permutes them across calls, and a stale
`click --on elem_44` re-resolves against the current tree and can silently hit a
different control. Measured on this machine: two back-to-back `see` calls drifted
from 41 to 42 elements and `elem_36`/`elem_37` swapped role. Passing a _stale_
`snapshot` does not protect you either, it is accepted and re-resolved loosely.
Capture a fresh `see` and pass that same call's `--snapshot` on every action.
Reusing one snapshot across several actions is fine and does stay pinned.

**`verify_state --on` does not accept `elem_N`.** It resolves the AX identifier
field only (for example `--on "First Text View"`), and it has no `--snapshot`
flag, so it re-derives its own tree. A `see` element ID passed to `verify_state`
fails with "No element matches identifier=elem_N". To verify an element, query it
by its accessible label, not its snapshot ID.

**`verify_state --window-exists` without a window selector can return `unknown`.**
With `--app X` alone it may burn the full timeout and answer "Verification
unknown / Window enumeration was incomplete" because accessibility window
enrichment dropped a row. This is reproducible on Finder and not on TextEdit, so
do not rely on it either way. Pass `--window-id` or `--pid` for a deterministic
answer; both are instant and both work, as does bundle-ID targeting.

**Clipboard slots work on this machine. Do not avoid them.** `clipboard save
--slot NAME` and `clipboard restore --slot NAME` round-trip correctly, including
two interleaved slots and across a Peekaboo daemon restart. `set`/`get` fidelity
is byte-exact including UTF-8. A report that slots "persist nothing" did not
reproduce here on macOS 27.2; if you ever see it fail, check the actual error
rather than assuming the feature is broken.

**Background `scroll` can fail on receipt validation.** It may report "Bridge
operation receipt does not match canonical target attribution" even though host
and client builds match. Pass an explicit `--snapshot`; that makes it either
work or refuse cleanly. Note background scroll also needs an AX-scrollable
element, which a plain text area is not.

That receipt error did not reproduce on this machine; what a plain text area
actually returns is a correct refusal: "Background scroll requires --on with an
Accessibility-scrollable element" or "Background scroll is Accessibility-only,
but Accessibility action is not supported". Both name a real remedy. Treat
either as intended behaviour, not a fault.

- Disambiguate multi-window apps with `window list --app X` and the `window_id`.
- Keyboard input works on this machine (macOS 27.2). Peekaboo usually delivers
  it through the accessibility value setter, and reports `effect:
"unverifiable"` for foreground keystrokes because it cannot read the change
  back. That is not the OS blocking input, so do not "fix" it by switching
  strategy.
- **TCC attributes permissions to the responsible process, not to peekaboo.**
  That is the parent of the opencode process, so it changes depending on how
  opencode was launched. When opencode runs as the Homebrew CLI in a terminal,
  the responsible app is the terminal (**Ghostty** as of 2026-10-08), _not_
  T3 Code (Nightly). Granting the wrong app looks like a working fix and is
  not: `peekaboo permissions` still reports Screen Recording denied while
  System Settings shows the toggle on for T3 Code. To identify the real
  responsible app, check `ps -p <opencode_pid> -o pid,ppid,comm` and resolve the
  parent to a bundle ID, then confirm against the TCC database:
  `sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "select client, auth_value from access where service='kTCCServiceScreenCapture'"`
  (`auth_value` 2 means granted). Check `peekaboo permissions` before
  concluding anything is broken.
- **The peekaboo MCP server needs `--allow-foreground` or foreground input is
  dead.** Bare `peekaboo mcp` starts the server with an immutable background-only
  execution policy, and every foreground request is then refused before dispatch
  with "Execution policy refused 'click' before dispatch ... a trusted caller
  must explicitly authorize foreground execution". This is peekaboo's own
  execution policy, not a macOS permission, so no amount of Screen Recording or
  Accessibility granting clears it. The fix is the launch command in
  `~/.config/opencode/opencode.json` under `mcp.servers.peekaboo.command`:
  `["peekaboo", "mcp", "--allow-foreground"]`. opencode reads MCP launch config
  once at startup, so editing it mid-session does nothing until opencode
  restarts; the giveaway that the flag took effect is the tool count rising from
  24 to 26 as `drag` and `move` become available.
- A successful foreground `click` returns "Click did not return a confirmed
  outcome. Follow the canonical escalation metadata before deciding whether to
  retry." That is the standard unverifiable-foreground path, not a failure, and
  not a reason to retry blindly, since a second click fires twice. Confirm with
  a fresh `see` or `inspect_ui` on the target and check the window title or
  state instead. Verified on this machine: a click that reported exactly that
  message had in fact navigated System Settings from General to Privacy &
  Security.

### maya-mcp (Autodesk Maya 2027)

**Who this is for.** Ryan is in ninth grade and this Maya work is for his modelling class. That
changes how to work, not whether to. Explain what a tool is doing and why before a wall of code, skip
the jargon dump, and assume he has not met a given Maya panel before. Keep operations reversible and
say which one you used, because a school project lost to a wrong click is not a funny story. Default to
building on a copy and confirm before anything that overwrites a file he made. The models are class
work, so treat them as deadline material: if something breaks, say so plainly and say what still
works rather than quietly starting over.

71 typed tools. Talks to Maya over `commandPort` on `127.0.0.1:7001`, opened
automatically at startup by `userSetup.py` in Maya's scripts dir. Loopback only,
with no authentication on the socket, so treat local access as equivalent to
running code as the user.

Standard flow: `maya.connect` -> `health.check` -> `scene.info` -> act ->
`scene.save_as`. **Verify visually** with `viewport.capture` and actually look at
the returned image before claiming success.

Launching Maya is the agent's job, not the user's: `open -a
/Applications/Autodesk/maya2027/Maya.app` from the shell, then poll until
`127.0.0.1:7001` accepts a connection. `userSetup.py` opens the port and kills
the Home Screen on startup, so roughly 10-20 seconds after launch Maya is ready
with no GUI interaction needed.

- Prefer typed tools (`modeling.*`, `nodes.*`, `shading.*`) for discrete
  operations. Use `script.execute` for anything multi-step. Scripts must live
  in `~/.config/opencode/maya-scripts/`, set via `MAYA_MCP_SCRIPT_DIRS`; any
  other path is rejected. With that env var unset you get `script.list`
  returning nothing and `script.execute` failing with "No script directories
  configured", which reads like a broken install but is just a missing var.
- `script.run` (arbitrary code) is disabled and should stay that way. Note this
  is not a strong boundary: the agent can write into the allowlisted directory,
  so `script.execute` can already run arbitrary code as the user.
- **Maya 2027 API traps, verified on this machine:**
  - `cmds.rotate` requires keyword args, e.g. `cmds.rotate(n, rotateY=-90)`.
    Positional raises `TypeError: Object 0 is invalid`.
  - `cmds.lookAt`, `cmds.fitView`, `cmds.getActivePanel` do not exist.
  - `cmds.dgdirty(all=True)` is invalid, use bare `cmds.dgdirty()`.
  - `modelPanel(..., shadingType=)` and `(..., grid=)` are invalid flags.
  - Do not rely on `viewFit` to frame geometry. Panel/view resolution from the
    commandPort context is unreliable and several of its flags are invalid.
    Set the camera transform directly instead. A camera looks down its local -Z;
    with default xyz rotate order that means
    `rotateX = asin(dy)`, `rotateY = atan2(-dx, -dz)`.
  - Call `cmds.refresh(force=True)` after camera moves. `viewport.capture` reads
    the panel image buffer, so without a redraw it returns a stale frame.
  - `viewport.capture` picks a panel in this order: the caller's `panel`
    argument, then `cmds.getPanel(withFocus=True)`, then the first visible
    panel, then `sorted(names)[0]`. `userSetup.py` focuses the persp viewport
    at startup and `frame_view.py` re-focuses it, so a capture with no `panel`
    argument now comes back in perspective. Passing `panel` explicitly is still
    the safer habit if focus has since moved.
- **Maya launches straight into a live viewport.** `userSetup.py` disables the
  Home Screen, which otherwise replaces the main window with a launcher and
  leaves no viewport at all. If you see a window titled just "AUTODESK MAYA
  2027" with no `Autodesk MAYA` in the title bar, that is the Home Screen and
  `viewport.capture` will return a meaningless grid. Dismiss it via peekaboo.
- Write scripts to be **idempotent**. They get run repeatedly in one session
  while an agent iterates. Delete prior geometry up front, or the second run
  silently doubles every count. Keep shading nodes and transforms on distinct
  name stems: a blinn node and a transform both named `shipHull` makes Maya
  uniquify the transform to `shipHull1`, which then defeats a cleanup pass that
  looks for `shipHull`. Namespace materials (`matHull`) separately.
- Never let a script swallow exceptions. Collect failures and surface them in
  the result so a partial failure cannot be reported as success.

### Driving Maya's GUI with computer-use

`computer-use` is the third MCP and the only one that gives real desktop input: screenshots for
seeing, the accessibility tree for targeting, clicks and keystrokes for acting. Maya's Qt UI is a
good target with specific holes. Read it with `read_screen({app: "Maya", max: 4000})`; at a 935x1035
window with the default layout that returned the entire tree, 606 nodes and 218 with labels, and
`truncated: false`.

- The panels are real. 122 `AXButton`, 160 `AXMenuItem`, 12 `AXTextField`, 165 `AXImage`, and
  `looksOpaque: false` with `contentNodes: 264`. The timeline, outliner, channel box and panel tabs
  come back with usable frames, for example `AXButton "openSceneButton" @1123,81 22x22`. The 3D
  viewport itself has no useful tree; everything around it does.
- Trust those frames for the panels, not for the viewport toolbar row. Probing four elements at
  their own reported centres with `element_at`, `Go to end of playback range`, `Play forwards` and
  the `Attribute Editor` tab each resolved to themselves, while the viewport panel toolbar row
  reported `y=201` and that point resolved to `AXMenuItem "Edit"`. Check with `element_at` before
  clicking anything in that row.
- The File row is pixels only. File, Edit, Create, Select, Modify, Display, Windows, Mesh, Edit Mesh
  and Mesh Tools are custom drawn. They are absent from the tree, and the macOS system menu bar
  exposes only zero size Apple/Maya/Window entries, so `computer_menu` and System Events cannot
  reach them at all. Click them by coordinate.
- Re-screenshot after every step inside a menu. Aiming at Create > Polygon Primitives using the
  coordinate read off the parent menu hit NURBS Primitives instead, because the list moves when a
  submenu opens. The click did what it was told; the coordinate had gone stale by one row, and the
  result was a NURBS sphere rather than a polygon one.
- A menu click is a real scene edit and the API confirms it. Create > a primitive flipped
  `scene_info.modified` from false to true, added `nurbsSphere1`, `nurbsSphereShape1` and
  `makeNurbSphere1` to `nodes_list`, and showed the selected sphere in both a screenshot and
  `viewport_capture`. Make that pair the verification step for anything done through the GUI.
- The Open dialog is Maya's own Qt browser, not a native panel, and it is fully AX exposed. The
  `Files` outline, `File name:` field, `Open` and `Cancel` all matched the pixels. The toolbar
  `openSceneButton` opens it directly. With a dirty scene it first asks "Warning: Scene Not Saved /
  Save changes to <scene>?" with Save, Don't Save and Cancel; after Don't Save the browser did not
  appear, so treat that prompt as ending the Open and start again from a clean scene.
- Put the file where the dialog already is rather than typing a path. Copying a folder into
  `~/Documents/maya/projects/default/scenes/` made it appear in the dialog list with no navigation
  at all. Typing into the `Look in` field is unverified on this machine.
- `computer_key` takes `mod`, and `modifiers` is now an accepted alias for it. Passing both with
  different values is an error rather than a silent pick. The result echoes the modifiers that
  reached the CLI, so `modifiers: ["shift"]` is proof the value parsed and `[]` means it did not.
- Use the API for values and the GUI for what the API cannot reach. Clicking a Channel Box field and
  typing into it means trusting focus; `attributes_set` and `modeling_*` do not.

**The file round trip is closed, but not through the file dialog** (Oct 21). Opening a scene via
Maya's GUI Open dialog wedges Maya every time it is accepted, so the working recipe opens with
`scene.open` over commandPort and keeps the GUI for the edit and the save:

1. Launch Maya, wait for commandPort 7001, then `maya.connect` and `health.check`.
2. `scene.open(file_path=...)` on the copy. Confirm `scene_info.file_path` and a non-default
   `frame_range`; the real scene reports `1231-1232`, not the empty scene's `1-120`.
3. Edit by clicking a real control. The Modeling shelf's `Polygon Cube` is AX-exposed at
   `1042,133 35x34` and one click created `pCube2`, which `nodes.list` confirms.
4. Save with the toolbar `saveSceneButton` at `1146,81 22x22`. Do not use `scene.save_as` here: the
   point is to prove the GUI save. `scene_info.modified` must flip back to false.
5. Verify three ways and trust none alone: `scene_info`, a screenshot, and the file on disk (hash
   `b41b95…` became `6f062d28…`, 71192 became 71888 bytes, mtime moved to today). Then `scene.new`
   with `force`, confirm the cube is gone, and `scene.open` the copy again: `pCube2` returning is
   what proves the edit reached the file rather than living in memory.
6. Delete the copy and the folder, then re-check the baseline hashes. All three originals in
   `~/Downloads/cte 3d model creative/` verified OK with untouched September mtimes, so the whole
   run can be redone on a copy without risk.

**Maya 2027.2 dies when its file dialog is accepted. Three launches, three hangs.** Clicking the
dialog's `Open` button (whether a folder or a file is selected) hangs the app, and macOS then shows
"An error has stopped Maya from working properly". Two different stacks, both sampled from a live
process:

- `NSAccessibilityChildren` calls `QCocoaAccessible::unignoredChildren`, which calls
  `NSAccessibilityUnignoredChildren`, which calls back into `NSAccessibilityChildren`, forever,
  until the stack dies. Pure recursion inside Qt's Cocoa accessibility bridge.
- No accessibility frame anywhere: `QmayaIconTextButton::mouseReleaseEvent` executes a command that
  enters `QDialog::exec()`, and inside that modal loop a second `QDialog::exec()` opens. Nested modal
  dialogs that never unwind.

The first crash made `read_screen` look guilty, since the fatal read landed right after the click.
**That theory is wrong.** The third crash had zero AX reads after the click, only screenshots and
`scene_info`, and still hung. Do not spend time re-testing it. Reads while the dialog is merely open
were safe every time; accepting it is what kills Maya. Drive the dialog only for browsing, and open
scenes through commandPort.

**The user will open files by hand. Ask them instead of fighting the dialog.** Ryan said on Oct 21
that he is happy to open scenes for the agent, which is the cleanest route: the human drives the
dialog, the agent never sends a click into it, and the failing ingredient is removed entirely. So
when a scene needs opening and the port route is not wanted, ask him to open it, then confirm with
`scene_info.file_path` before doing any work. Do not assume he opened the file you named, and do not
skip the check: the whole point is that nothing else in the run tells you which scene is live. This
is a workaround, not a proven fix. No run has tested a human accepting that dialog while an agent
session was live, so if Maya still wedges with a human at the keyboard, the Qt bug is worse than
synthetic clicks and the port route is the only one left.

**After a SIGKILL, the next Maya launch cannot bind port 7001.** `userSetup.py` runs at startup, its
bind loses to the socket the killed process left behind, and the port never opens. Quit with Cmd+Q
(`computer_key` with `key: "q"`, `modifiers: "cmd"`) and relaunch: 8 seconds to a listening port,
against never. Opening it by hand from the MEL line is worse than useless, because a bare
`commandPort -n ":7001"` creates a MEL-only port. The MCP then reports
`Cannot connect to Maya commandPort`, and the real reason is sitting in `health.last_error` as
"compatibility probe returned an invalid response". The port needs `sourceType="python"` with
`echoOutput=True`, which is what `userSetup.py` already does. Secondary trap: clicking the MEL field
at its reported frame does not reliably focus it, so keystrokes go to the viewport, and the digits in
a port number flip Maya into another layout instead of running the command.

**Check `~/Library/Logs/Maya/maya-mcp-startup.log` when the port is dead.** `userSetup.py` now logs
every startup attempt there, one line per event, because the failure is otherwise invisible: Maya
starts fine, looks normal, and simply has no port. Reproduced deliberately on Oct 21 by holding a
port from outside Maya, which is what a killed Maya leaves behind. The real exception is
`RuntimeError: Socket Error: No command port created ... (:PORT (48))`, and `48` is `EADDRINUSE`, so
the bind is losing to a live socket, not failing for a permissions or DNS reason. `enable_commandport`
retries five times a second apart and then logs `GAVE UP`. The retry is a guess; the log is the actual
fix. Two behaviours to keep when editing it: an already-listening port is left alone rather than torn
down and rebuilt (rebuilding drops the connected client mid-session), and `_log` flattens newlines so
a multi-line Autodesk message stays one line. Verify an edit to that file with `importlib.reload` from
`script_execute`, not by restarting Maya, since a syntax error there only appears at the next launch.

**Batch edits into one named undo step.** `maya-scripts/undo_chunk.py` takes
`{"action": "open", "name": "build crate"}` and `{"action": "close"}`, wrapping the work in
`undoInfo(openChunk=True, chunkName=...)`. Without the name, Maya names the chunk after whichever
command ran last: one tested batch came back as `setFilterScript "initialShadingGroup"`, which tells
nobody anything. `maya-scripts/undo_step.py` undoes one step and reports what it was. Verified
end-to-end Oct 21: three primitives created inside a chunk disappeared on a single `undo_step`, and
`undone` came back as the chunk's name instead of null. It works because `undoName` is read _before_
`cmds.undo()`, since afterwards it points at the next step back. `undo_step.py` also sends a
`closeChunk` first, because a chunk left open by a failed batch would otherwise make one undo swallow
an unbounded amount of work. There is no query for whether a chunk is open, so a mid-batch failure
must still send the close.

**Never drive a GUI while another session is injecting input.** Check with
`pgrep -fl computer-use` first; three server instances means three sessions can move the pointer.
While another session was live, a T3 Code prompt appeared in a Maya dialog field under the cursor,
85 characters typed by this session could not be found in either app's tree, and T3 Code resized
itself on top of Maya. Maya then hung inside a mouse event handler and macOS killed it.
`computer_type` and `computer_key` take an optional `app`, and then refuse to send anything unless
that app is frontmost, naming the app that would have received the input instead. Use it for
anything that matters. Without `app` the input still goes to whatever holds focus, and a collision
is indistinguishable from a bug after the fact. Both tools also echo `receivedBy`, the app that
was frontmost when the input was sent, read just before sending it, so a surprise shows up in the
result instead of silently. The `app` match is exact and case-insensitive against the app name or
its bundle id, so a partial name is refused rather than guessed. That exactness matters: the old
substring match accepted `app: "Code"` while Visual Studio Code was frontmost.

**A hung app is now named as one.** `read_screen` used to answer `no windows found for 'Maya'`
while `list_windows` still listed the window, which sent a session hunting a permissions problem
it never had. The helper separates the three causes that used to look identical: this process
lacking Accessibility permission, a running app with no on-screen windows, and a window that is on
screen while the app's accessibility API answers nothing. The last one says the app is running and
visible but not answering, that it is likely hung or busy rather than absent, points at
`sample <pid>`, and suggests screenshots with coordinates meanwhile. Reproduced by stopping TextEdit
with `kill -STOP`: the new message arrives in 3 seconds. `sample <pid>` on the real Maya hung pinned
the main thread in `QGuiApplicationPrivate::processMouseEvent`, a mouse event handler rather than a
file dialog.

### computer-use: known defects

- **A refused activation reports itself but does not fail.** `computer_app activate` returns
  `requested` and `frontmostNow`; read them. It does not retry and does not error.
- Nits: `captureAsPng` is a constant `true` with a dead branch, which warns on every build;
  `resample`'s `-Z` branch is unreachable; the harness checks window positions against the main
  display, so a display above the main one fails it for no reason.

### Driving chat and message composers

Rule learned from Codex's computer-use app playbooks, and it applies anywhere an
agent types into a UI that has a default-button action: Slack, Discord, Mail,
Messages, iMessage, a search field, anything with a Send button.

- **Prefer `set_value` over `type` for message composers.** With a newline in
  the string, `set_value` inserts a line break, while `type` can send the
  message instead. One stray newline and the agent has posted to a channel or
  emailed a human.
- **Never send text containing `\n` through `type` in any composer.** Strip new
  lines, or switch to `set_value`, or type line by line.
- **Make sure the intended field is focused before pressing Return.** A
  composer with nothing focused swallows the keystroke somewhere else, or the
  Return lands on whatever was frontmost.
- **Treat a screenshot as the source of truth when the accessibility tree looks
  wrong.** Some app UIs report stale or misleading AX text.
- In spreadsheet apps, one click appends to a cell and three clicks replace its
  contents, and batching several rows or several formulas into a single type
  call fails. Click to select, then type the value.

### Combining both

Maya's viewport is a 3D canvas with no useful accessibility tree. Use the API
for geometry and `computer-use` for GUI work, as in the section above:
`computer-use` to see the window and click it, the API to build, then
`viewport.capture` to verify the result. When a capture and the API disagree,
trust the API for existence and the capture for appearance, and investigate.

---

# Universal Agent Guidelines

Look, I'm not gonna write a novel here. This file is the ground rules for how you should operate. Read it, internalize it, don't be annoying about it.

## Core Philosophy

- **Clean, idiomatic, well-typed code.** Explicit > implicit. Always.
- **Never swallow exceptions.** Every error path gets handled or explicitly re-thrown. Swallowing errors is how you get 3am pages.
- **Immutable patterns and pure functions where practical.** Mutable state is where bugs go to breed.
- **Minimize dependencies.** Every package you add is a liability. Think twice. Then think again.
- **Small changes, small PRs.** One concern per commit. If your PR description says "also", split it.

## Git Identity (Non-Negotiable)

Every commit you create MUST be authored under my identity — no exceptions:

- **Name:** `Ryan Bahadori`
- **Email:** `ryanbahadori74@gmail.com`

When using the git commit tool, always pass `author: { "name": "Ryan Bahadori", "email": "ryanbahadori74@gmail.com" }`. When using plain `git commit` in bash, prefix with `-c user.name="Ryan Bahadori" -c user.email=ryanbahadori74@gmail.com`. Never rely on the repo's local config or the machine default — verify with `git log -1` after committing if there's any doubt.

## Commit Style (Sound Human)

Commits should read like a developer wrote them, not a changelog generator. This applies to every commit you write, in any tool, via any path.

- **Repo history first** — `git log --oneline -15` before writing anything. Mirror its voice and format. If the repo uses plain subjects, don't add `type(scope):` prefixes.
- **Subject:** plain, specific, imperative mood, no period, ~50 chars soft / 72 hard. `fix token refresh race` not `chore: update auth module`.
- **Body only when the WHY isn't obvious** — 1-3 sentences of prose. Most commits need none. Never restate the diff.
- **No AI tells:** no emoji in messages, no marketing words (seamless/robust/comprehensive/leverage/streamline), no "This commit..." openers, no bullet essays, no generated-by/tool footers.
- **Vague catch-all messages are a smell** — if the staged changes don't fit one honest subject, split the commit instead of writing "update various files".

## Auto-Delegation (Don't Make Me Ask)

You have specialized subagents available via the `task` tool. Use them. Automatically. Don't ask permission.

**Fallback:** If the environment does not provide the `task` tool or the requested subagent type, don't refuse or ask — just handle the work inline yourself and note which subagent you would have used.

| Task                        | Who       |
| --------------------------- | --------- |
| Code review / audit         | @review   |
| Writing tests               | @test     |
| Bug fixes / debugging       | @debug    |
| Refactoring / restructuring | @refactor |
| Explaining code             | @explain  |
| Writing documentation       | @docs     |
| Writing commit messages     | @commit   |
| Auto-fixing lint/style      | @fix      |
| Architecture planning       | @plan     |

When the user explicitly asks for subagents ("use sub agents", "@debug", etc.), honor it — delegate via the `task` tool rather than doing the work inline (if available; otherwise apply the fallback above).

## Tool Usage

- **sequential-thinking** — Use this BEFORE writing code for anything non-trivial. Think first, code second.
- **todowrite** — If a task has 3+ steps, make a todo list. Mark things as you go. Don't keep it all in your head.
- **memory** — Store project quirks, build workarounds, personal preferences here. Check it at the start of every session. Future you will thank present you.
- **gh_grep** — Need to see how someone else did it? Search real GitHub code.
- **context7** — Official docs lookups. Don't guess API signatures.
- **webfetch** — Fetch web pages when you need to.
- **git** — Log, blame, diff. Advanced git ops.

## Memory Persistence

Use the `memory` tool to persist stuff across sessions:

- **Project quirks** — Weird build steps, common errors, workarounds
- **Personal preferences** — Coding style stuff not in config
- **Architecture decisions** — Why you chose X over Y
- **Startup check** — Beginning of each session, check memory for relevant context

## Skills

Skills are reusable workflow instructions stored as `SKILL.md` files under `~/.config/opencode/skills/<name>/`. Load them via your environment's skill mechanism if available; otherwise read the file directly and follow it. Don't wait to be told — when a situation in the routing table matches, act on it proactively.

### Auto-trigger routing

| Situation                                                       | Skill                                                                                                    |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| User asks for a non-trivial feature, refactor, or design change | **grill-with-docs** — interview BEFORE writing code; build the project's CONTEXT.md vocabulary as you go |
| User floats an underbaked plan, idea, or decision (non-code)    | **grill-me**                                                                                             |
| Alignment reached on spec-worthy work                           | **to-spec** to publish it, then offer **to-tickets**                                                     |
| Executing a spec or tickets                                     | **implement** — drives tdd + code-review at pre-agreed seams                                             |
| Building anything with testable behavior                        | **tdd** — red-green-refactor, failing test FIRST                                                         |
| Bug resists the obvious fix, or repro is unclear                | **diagnosing-bugs** — feedback loop → minimise → hypothesise → fix → regression-test                     |
| Meaningful changes done, about to commit                        | **code-review** before committing                                                                        |
| User says "wait what", "huh?", or clearly didn't follow         | **wait-what** — re-pitch with the missing context, plain English                                         |
| Long session wrapping up with work remaining                    | **handoff** — compact into a handoff doc for the next agent                                              |
| User mentions shoehorn / `as` assertions in tests               | **migrate-to-shoehorn**                                                                                  |
| User wants pre-commit hooks / Husky / lint-staged               | **setup-pre-commit**                                                                                     |
| User wants exercise scaffolds (sections/problems/solutions)     | **scaffold-exercises**                                                                                   |
| Writing docs, commit messages, PR descriptions                  | **unslop** — cut AI tells, add human voice                                                               |

Composition with existing workflows: **testing-workflow** still governs test style and framework discovery; **tdd** governs the dev loop. **debugging-workflow** handles simple bugs; when it gets hard, **diagnosing-bugs** takes over.

### Escalation offers (suggest it, don't auto-run it)

- Codebase feeling like a ball of mud, recurring design complaints → offer **improve-codebase-architecture**
- Work too big for one session → offer **wayfinder** (requires tracker setup)
- Issue backlog duty → offer **triage** (requires tracker setup)

### Manual only — never auto-run

- **setup-matt-pocock-skills** — one-time per-repo setup, ONLY on explicit request
- **ask-matt**, **teach**, **to-questionnaire** — on request

### Grilling guardrails

- Skip grilling for trivial work: typo fixes, one-liners, direct questions, config tweaks.
- Never grill the same topic twice in a session. Once we're aligned, build.

## Testing

- Run the existing test suite before AND after making changes.
- Add tests for new functionality. Match the style of existing tests.
- For bugs: write a failing test FIRST, then fix the code. It's not that hard.

## Language-Specific Commands

- TypeScript: `tsc --noEmit` for type checking
- Rust: `cargo check` before `cargo build`
- Go: `go vet ./...` alongside `go build ./...`
- Python: `ruff check .` and `mypy .`
- Use `npm run lint` / `cargo clippy` / `golangci-lint run` when available

## Communication

- Explain WHY, not just WHAT. Surface tradeoffs and alternatives.
- If something's ambiguous, list your assumptions and ask. Don't guess.
- Be concise. Don't write essays. Get to the point.

## Writing: cut AI tells

Applies to prose you authored: docs, commit messages, PR bodies, ADRs, code comments, chat replies. Not generated artifacts, quoted third-party text, license boilerplate, or a file with an existing house style. Match the surrounding code first.

When these rules conflict, meaning wins. If following one would change what the text says, skip it and say why.

### Gate: check before you output, not after

Scan your draft for: em dashes, colons used as mid-sentence connectors, hedges, forced groups of three, and the phrases below. Fix them before responding. Do not wait until the text is finished to notice.

### Add soul

Removing tells is half the job. Sterile writing is as obvious as slop.

- Have opinions. React to facts instead of listing pros and cons neutrally.
- Vary rhythm. Short sentences, then longer ones that take their time.
- Acknowledge complexity. "Impressive but also kind of unsettling" beats "impressive."
- Use "I" when it fits.
- Let some mess in. Perfect structure looks machine-made.
- Be specific. Not "this is concerning" but "there's something unsettling about agents churning at 3am."

### The tells

Content:

- Puffery: pivotal, testament to, evolving landscape, setting the stage for, indelible mark, deeply rooted. State what happened.
- Name-dropping outlets with no context. Pick one, say what was said.
- Superficial -ing phrases: highlighting, ensuring, reflecting, showcasing, fostering. Delete or expand with a real source.
- Promotional language: nestled, vibrant, breathtaking, groundbreaking, renowned, stunning, must-visit. Use neutral description.
- Vague attributions: "Experts believe", "Industry reports suggest". Name the source or delete.
- Formulaic challenges: "Despite challenges... continues to thrive". Use specific facts.

Language:

- AI vocabulary: additionally, crucial, delve, enduring, enhance, garner, interplay, intricate, pivotal, underscore, vibrant. Plain words.
- Fancy ways to say "is": serves as, stands as, boasts, features. Just say is or has.
- "Not just X, but Y." State the point directly. If Y is what matters, say only Y.
- Rule of three: forcing ideas into groups of three. Use the natural number. Two or five is fine.
- Synonym cycling: protagonist, main character, central figure, hero in one paragraph. Pick one, repeat it.
- False ranges: "from X to Y" where neither end is on a meaningful scale. List topics.

Style:

- Em dashes. Never. Use periods or commas. Do not substitute parentheses, en dashes, or hyphen-as-dash; those are the same tell.
- Colons. Fine before a list, a definition you're introducing, or a line of code. Not as mid-sentence connectors.
- Comparison framing: "Instead of X, you do Y" and "whereas X does Y". The parallel is the tell, not the punctuation. State only what you're recommending.
- Boldface overuse. Don't bold every proper noun.
- Inline-header lists: "**Performance:** Performance improved..." is a tell. A bold lead-in that ends in a period and is followed by genuinely new detail is fine.
- Title case headings. Use sentence case.
- Decorative emoji in headings and bullets.
- Curly quotes. Use straight quotes.

Chat artifacts:

- "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!". Remove.
- Cutoff disclaimers: "While specific details are limited...". Find sources or remove.
- Sycophancy: "Great question! You're absolutely right!". Respond directly.

Filler:

- "In order to" is "to". "Due to the fact that" is "Because". "It is important to note that" gets deleted.
- Hedging stacks: "could potentially possibly be argued that it might" is "may".
- Generic conclusions: "The future looks bright." State specific plans or facts.

Jargon, always:

- substrate, wedge, nexus, vantage, locus, gold-plating, endgame, north star, flywheel, ratchet. Read as technical, usually have a plainer word. "Substrate" becomes "base". "Wedge in" becomes "add". "Gold-plating" becomes "more than the job needs".

Jargon, technical writing only:

- harness, scaffolding, vector, modality, primitive, surface, evacuate, bedrock, paradigm. Fine in an internal engineering doc, wrong elsewhere. "Evacuate the handler" becomes "move the handler out".

Plain speech:

- Say what it does, not how it feels. "The database stays close at hand" names a feeling. Name the mechanism or a number: `.toSQL()` returns the exact string sent to the database. If you can't restate it as an instruction, fact, or number, cut it. If it could appear unchanged in another project's docs, it says nothing about this one.
- Shorten or split dense sentences. One idea per sentence.
- Active voice. Name the actor: "queries are validated" becomes "the compiler validates queries".
- Cut adverbs or use a stronger verb. "runs quickly" becomes "is fast" or the actual number.
- Plain word over fancy synonym: utilize, leverage, facilitate, numerous, in the event that.

### Flag what you invented

Rule about vagueness catches details that are too soft. This catches the opposite: specific, concrete, and made up.

If you cannot verify a specific from something the reader can check, say so. "These are conventions I picked, confirm against the real package" is a strength. Silence reads as confidence the knowledge does not support.

- Invented identifier or key: "jobs land in `<name>:dlq`" becomes "jobs land in a dead-letter key; confirm the exact name."
- Invented config shape: "confirm the connection options shape."
- Guessed version, count, or behavior: hedge it or cut it.

Do not do this for facts you actually know, or it becomes its own tell. The line sits between "I chose this, go check it" and "this is how it is."

### Worked example

Before:

> It's a robust, battle-tested solution that streamlines the workflow, showcasing significant improvements, like 40% faster processing, and ensuring your team can move faster.

After:

> It cuts processing time by 40%. Ask the team that owns it why the rewrite was worth it.

Rule "plain word" took "streamlines". Puffery took "robust, battle-tested". The -ing rule took "showcasing". The em dash rule took the dashes. "Say what it does" took "move faster", which could have appeared in any project's docs, so it became a question with a name attached.

The 40% stayed. Numbers are not a tell, and a pass that deletes the one concrete fact has gone too far.

## Review Checklist

- Dead code, unused imports, missing error handling
- Security: XSS, injection, secrets exposure
- Public API clarity — can someone figure out how to use this without reading the implementation?
- Every PR should be understandable in under 2 minutes
