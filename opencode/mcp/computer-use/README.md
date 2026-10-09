# opencode-computer-use

MCP server that lets opencode control macOS: screenshots, mouse, keyboard, the
accessibility tree, and app/window management.

Built for testing apps the way users actually use them — by clicking around.

## Setup

Register the server with opencode:

```json
{
  "mcp": {
    "servers": {
      "computer-use": {
        "type": "local",
        "command": ["node", "/path/to/opencode-computer-use/dist/index.js"],
        "disabled": false
      }
    }
  }
}
```

Then build and check permissions:

```sh
npm install
npm run build        # compiles swift/ComputerUse.swift, then dist/index.js
npm test             # end-to-end suite against the real desktop
./bin/computeruse perms
```

`npm run build` creates `bin/` itself, so a clean checkout works. The host app
needs Accessibility and Screen Recording, granted under System Settings >
Privacy & Security. Verify with `computer_permissions`.

## Tools

| Tool                    | What it does                                                                                                                                                               |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `computer_permissions`  | Report Accessibility and Screen Recording grants                                                                                                                           |
| `computer_screenshot`   | Capture screen / region / display, returned as an image the model can see (JPEG, or PNG via `png`). Scaled to screen points unless `fullRes`; reports `scale` and `origin` |
| `computer_screeninfo`   | Display bounds, so coordinates can be reasoned about per display                                                                                                           |
| `computer_click`        | Click at a point, with button and modifier support                                                                                                                         |
| `computer_move`         | Move the pointer without clicking                                                                                                                                          |
| `computer_drag`         | Drag from one point to another                                                                                                                                             |
| `computer_scroll`       | Scroll by delta at a point                                                                                                                                                 |
| `computer_type`         | Type literal text                                                                                                                                                          |
| `computer_key`          | Send a key with modifiers, optionally repeated                                                                                                                             |
| `computer_list_windows` | On-screen windows with frames                                                                                                                                              |
| `computer_read_screen`  | Accessibility tree for an app, with `looksOpaque` and `nodes`                                                                                                              |
| `computer_element_at`   | The accessibility element at a point, plus what the OS hit test said                                                                                                       |
| `computer_list_apps`    | Running apps with bundle ids and frontmost flag                                                                                                                            |
| `computer_app`          | `launch`, `activate`, `quit`, `list`                                                                                                                                       |
| `computer_menu`         | Click a menu path, e.g. `File` > `Open…`                                                                                                                                   |
| `computer_applescript`  | Arbitrary AppleScript escape hatch                                                                                                                                         |
| `computer_wait`         | Sleep, for waiting on animations                                                                                                                                           |

## CLI

Every tool is also a subcommand, which makes the behaviour inspectable without
an MCP client in the loop. All output is JSON on stdout.

```sh
./bin/computeruse ax --app "T3 Code (Nightly)" --max 4000
./bin/computeruse axpoint 91 45
./bin/computeruse screenshot --out /tmp/shot.png --png --full-res
./bin/computeruse activate "TextEdit" --clamp
./bin/computeruse axsync --selftest
```

Subcommands: `perms`, `screeninfo`, `screenshot`, `cursor`, `move`, `click`,
`drag`, `scroll`, `type`, `key`, `apps`, `frontapp`, `launch`, `activate`,
`quit`, `windows`, `ax`, `axsync`, `axpoint`, `menu`.

`axsync --selftest` runs the frame matcher against synthetic cases and exits
nonzero on failure, so it is usable from a script or CI.

## Behaviour worth knowing

- Screenshots are scaled so 1 image pixel = 1 screen point, so coordinates read off an image can be passed straight to `computer_click`. `fullRes` and `png` are independent: `fullRes` keeps native Retina pixels (divide image coordinates by the reported `scale`), `png` only changes the encoding. Captures are taken as PNG and encoded once, so small text does not get two lossy passes. Scaling never enlarges, so a region running off the edge of a display comes back smaller than requested with an honest `scale` below 1. A whole-screen capture spanning several displays reports `origin`, since its pixel (0,0) is not global (0,0).

- Electron apps that do not bridge their web contents to the accessibility API expose the whole UI as one `AXGroup`. `computer_read_screen` sets `looksOpaque` plus `opacityReason` and a `hint`, so a shallow tree is not mistaken for a real one. `looksOpaque` is `null` when the verdict would be unreliable, which is the case when the tree was truncated or the app had no windows, so check `opacityReason` before trusting it. There is no way to see inside such an app from outside: use `computer_screenshot` with coordinates, or `computer_applescript`.

- `computer_app` with `activate` un-minimizes windows and reports what it changed in `repaired`. It deliberately does **not** reposition windows that are only partly off a display, because that is usually deliberate and a window on another Space is never on-screen to begin with. The CLI's `--clamp` opts into the aggressive repair if you want it.

- Electron caches AX frames, so right after a window moves the tree can report the old window rect. `ax`, `axpoint` and `read_screen` wait for the tree to agree with the window server before answering, and report `axSettled` plus `settleWaitedMs`. `axSettled` is `null` when no check ran, so it never claims a check it skipped. The comparison is window-level only, because the window server knows nothing about child elements: a resize where the window frame is current but its children are not is not detected. `--no-wait` skips the wait entirely.

- `AXUIElementCopyElementAtPosition` answers with whatever sits highest in the tree, which on an Electron window is the whole-window web-content group even when a native control is drawn over it. `computer_element_at` descends from the topmost on-screen window instead and reports `source` (`descend` or `hittest`), so you can tell which answer you got. `osHitTestRole` is kept alongside for comparison.

- A window manager can re-tile between two reads. Coordinates taken before a move are stale, and `ax` on one app can hand back a tree from another. Re-read rather than caching frames.

## Safety

- All actions happen on your real user session with your real permissions. There is no sandbox.
- The `computer_applescript` tool is an arbitrary-code escape hatch — treat it accordingly.
- Nothing is sent anywhere except between opencode and the local server process.

## Known limitations

- Menu traversal uses System Events (AppleScript) rather than raw AX — more reliable across macOS versions, but requires the host app to have Automation permission on first use.
- macOS 26's SwiftUI apps (e.g. Calculator) expose empty button titles in AX — use `computer_screenshot` + visual coordinates for those.
- Screenshots are scaled to screen points, so a capture of a 1920x1080 display comes back 1920x1080. Pass `full-res` in the CLI (or `fullRes` in the tool) when you need native Retina pixels instead.

## License

MIT

---

<div align="center">
Built for testing apps the way users actually use them — by clicking around.
