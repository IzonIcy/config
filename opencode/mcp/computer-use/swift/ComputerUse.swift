// ComputerUse.swift — macOS automation CLI used by the opencode computer-use MCP server.
// Subcommands: perms, screeninfo, screenshot, cursor, move, click, drag, scroll,
//              type, key, apps, frontapp, launch, activate, quit, windows, ax, axpoint, menu
// Build: swiftc swift/ComputerUse.swift -o bin/computeruse -O -framework AppKit -framework ApplicationServices -framework CoreGraphics -framework ImageIO

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let SRC = CGEventSource(stateID: .combinedSessionState)

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write("ERROR: \(msg)\n".data(using: .utf8)!)
    exit(1)
}

func emit(_ obj: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]) else {
        fail("could not serialize JSON")
    }
    print(String(data: data, encoding: .utf8)!)
}

// MARK: - CLI arg parsing

struct Args {
    var flags: [String: String] = [:]
    var positional: [String] = []
    var has: Set<String> = []
}

func parseArgs() -> Args {
    var a = Args()
    let argv = Array(CommandLine.arguments.dropFirst())
    var i = 0
    while i < argv.count {
        let tok = argv[i]
        if tok.hasPrefix("--") {
            let name = String(tok.dropFirst(2))
            if i + 1 < argv.count, !argv[i + 1].hasPrefix("--") {
                a.flags[name] = argv[i + 1]
                i += 2
            } else {
                a.has.insert(name)
                i += 1
            }
        } else {
            a.positional.append(tok)
            i += 1
        }
    }
    return a
}

let args = parseArgs()
let cmd = args.positional.first ?? ""
let rest = Array(args.positional.dropFirst())

func intFlag(_ name: String, _ def: Int) -> Int {
    guard let s = args.flags[name] else { return def }
    guard let v = Int(s) else { fail("--\(name) must be an integer, got '\(s)'") }
    return v
}
func doubleFlag(_ name: String, _ def: Double) -> Double {
    guard let s = args.flags[name] else { return def }
    guard let v = Double(s) else { fail("--\(name) must be a number, got '\(s)'") }
    return v
}

// MARK: - AX helpers

func axString(_ el: AXUIElement, _ attr: String) -> String? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success,
          CFGetTypeID(v!) == CFStringGetTypeID() else { return nil }
    return v as? String
}

func axNumberString(_ el: AXUIElement, _ attr: String) -> String? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success else { return nil }
    let val = v!
    switch CFGetTypeID(val) {
    case CFStringGetTypeID(): return val as? String
    case CFNumberGetTypeID(), CFBooleanGetTypeID(): return "\(val)"
    default: return nil
    }
}

func axPoint(_ el: AXUIElement, _ attr: String) -> CGPoint? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success,
          CFGetTypeID(v!) == AXValueGetTypeID() else { return nil }
    let axv = v as! AXValue
    guard AXValueGetType(axv) == .cgPoint else { return nil }
    var p = CGPoint.zero
    AXValueGetValue(axv, .cgPoint, &p)
    return p
}

func axSize(_ el: AXUIElement, _ attr: String) -> CGSize? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success,
          CFGetTypeID(v!) == AXValueGetTypeID() else { return nil }
    let axv = v as! AXValue
    guard AXValueGetType(axv) == .cgSize else { return nil }
    var s = CGSize.zero
    AXValueGetValue(axv, .cgSize, &s)
    return s
}

func axChildren(_ el: AXUIElement) -> [AXUIElement]? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, kAXChildrenAttribute as CFString, &v) == .success,
          let arr = v as? [AXUIElement] else { return nil }
    return arr
}

func axElement(_ el: AXUIElement, _ attr: String) -> AXUIElement? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success,
          CFGetTypeID(v!) == AXUIElementGetTypeID() else { return nil }
    return (v as! AXUIElement)
}

func axSetBool(_ el: AXUIElement, _ attr: String, _ v: Bool) -> Bool {
    AXUIElementSetAttributeValue(el, attr as CFString, v ? kCFBooleanTrue : kCFBooleanFalse) == .success
}

func axSetPoint(_ el: AXUIElement, _ attr: String, _ p: CGPoint) -> Bool {
    var pt = p
    guard let v = AXValueCreate(.cgPoint, &pt) else { return false }
    return AXUIElementSetAttributeValue(el, attr as CFString, v) == .success
}

// Display bounds in the same top-left-origin space as AX and CGWindowList.
// NSScreen.frame is bottom-left origin, so it must not be mixed in here.
func displayBoundsTopLeft() -> [CGRect] {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    guard count > 0 else { return [] }
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    CGGetActiveDisplayList(count, &ids, &count)
    return ids.map { CGDisplayBounds($0) }
}

// The main display, chosen by contract rather than by array position:
// CGGetActiveDisplayList makes no ordering promise.
func mainDisplayBoundsTopLeft() -> CGRect? {
    CGDisplayBounds(CGMainDisplayID())
}

func onScreenFraction(_ f: CGRect) -> Double {
    let area = f.width * f.height
    guard area > 0 else { return 0 }
    var best = 0.0
    for d in displayBoundsTopLeft() {
        let i = f.intersection(d)
        guard !i.isNull, !i.isEmpty else { continue }
        best = max(best, (i.width * i.height) / area)
    }
    return best
}

// Put an app's windows back into a usable state after activate().
//
// Un-minimizing is always safe and fixes a real observed failure: activate() could
// return with the window still flagged minimized.
//
// Re-placing a window that is only partly on a display is NOT safe to do by default.
// A window parked half off-screen is often deliberate, and a window belonging to
// another Space is never in the on-screen window list at all, so it looks stranded
// when it is perfectly placed. So that part is opt-in via `clamp`.
func repairWindows(pid: pid_t, clamp: Bool) -> [String] {
    var repairs: [String] = []
    let appEl = AXUIElementCreateApplication(pid)
    guard let wins = axChildren(appEl) else { return repairs }
    for (i, w) in wins.enumerated() {
        guard axString(w, kAXRoleAttribute as String) == (kAXWindowRole as String) else { continue }
        if axNumberString(w, kAXMinimizedAttribute as String) == "1" {
            if axSetBool(w, kAXMinimizedAttribute as String, false) {
                repairs.append("window \(i): un-minimized")
                usleep(300_000)
            }
        }
        guard clamp else { continue }
        // Less than half the window on a display means it is effectively unreachable.
        // Exactly half is left alone: that is still a usable amount of window.
        guard let f = axFrame(w),
              f.width >= MIN_TRACKED_WINDOW, f.height >= MIN_TRACKED_WINDOW,
              onScreenFraction(f) < 0.5 else { continue }
        guard let primary = mainDisplayBoundsTopLeft() else { continue }
        // Clear the menu bar, and cascade so multiple repairs do not stack up.
        let inset: CGFloat = 32
        let x = primary.minX + inset + CGFloat(i) * 28
        let y = primary.minY + inset + CGFloat(i) * 28
        if axSetPoint(w, kAXPositionAttribute as String, CGPoint(x: x, y: y)) {
            repairs.append("window \(i): moved on screen from \(Int(f.minX)),\(Int(f.minY))")
        }
    }
    return repairs
}

var nodeBudget = 600
var nodeBudgetMax = 600
var nodesVisited = 0

func resetNodeBudget(_ max: Int) {
    nodeBudget = max
    nodeBudgetMax = max
    nodesVisited = 0
}

func axNode(_ el: AXUIElement, depth: Int, maxDepth: Int) -> [String: Any] {
    var node: [String: Any] = [:]
    node["role"] = axString(el, kAXRoleAttribute as String) ?? "unknown"
    if let sr = axString(el, kAXSubroleAttribute as String), !sr.isEmpty { node["subrole"] = sr }
    if let t = axString(el, kAXTitleAttribute as String), !t.isEmpty { node["title"] = String(t.prefix(200)) }
    if let v = axNumberString(el, kAXValueAttribute as String), !v.isEmpty { node["value"] = String(v.prefix(300)) }
    if let p = axPoint(el, kAXPositionAttribute as String) { node["pos"] = [round(p.x), round(p.y)] }
    if let s = axSize(el, kAXSizeAttribute as String) { node["size"] = [round(s.width), round(s.height)] }
    if axString(el, kAXFocusedAttribute as String) == "1" { node["focused"] = true }
    nodeBudget -= 1
    nodesVisited += 1
    if depth < maxDepth, nodeBudget > 0, let kids = axChildren(el) {
        var out: [[String: Any]] = []
        for k in kids {
            if nodeBudget <= 0 { break }
            out.append(axNode(k, depth: depth + 1, maxDepth: maxDepth))
        }
        if !out.isEmpty { node["children"] = out }
    }
    return node
}

// MARK: - Hit testing

func axFrame(_ el: AXUIElement) -> CGRect? {
    guard let p = axPoint(el, kAXPositionAttribute as String),
          let s = axSize(el, kAXSizeAttribute as String) else { return nil }
    return CGRect(x: p.x, y: p.y, width: s.width, height: s.height)
}

func frameContains(_ el: AXUIElement, _ pt: CGPoint) -> Bool {
    guard let f = axFrame(el) else { return false }
    return f.contains(pt)
}

// AXUIElementCopyElementAtPosition answers with whatever sits highest in the
// accessibility tree, which for an Electron/Chromium window is the whole-window
// web-content group even when a native control (e.g. a titlebar button) is drawn
// on top and swallows the click. Descent to the smallest containing child instead,
// so we report the element that would actually receive the click.
// Each level is a synchronous AX round trip, and a Chromium web view can hold
// thousands of nodes, so bound both depth and total children inspected.
// Roles that are the click target themselves. A click anywhere inside one of these is
// delivered to the control, never to whatever it draws internally, so the descent must
// stop there. macOS nests an AXGroup glyph inside the green fullscreen button, and
// descending past the control reported that inner node, which has no action of its own.
let CONTROL_ROLES: Set<String> = [
    "AXButton", "AXMenuButton", "AXPopUpButton", "AXCheckBox", "AXRadioButton",
    "AXTextField", "AXTextArea", "AXComboBox", "AXSlider", "AXIncrementor",
    "AXStepper", "AXColorWell", "AXDisclosureTriangle", "AXTabButton", "AXLink",
]

func deepestLeaf(_ root: AXUIElement, _ pt: CGPoint, maxDepth: Int = 24, maxNodes: Int = 2000) -> AXUIElement {
    var best = root
    var cur = root
    var inspected = 0
    for _ in 0..<maxDepth {
        if CONTROL_ROLES.contains(axString(cur, kAXRoleAttribute as String) ?? "") { break }
        guard let kids = axChildren(cur) else { break }
        inspected += kids.count
        if inspected > maxNodes { break }
        var next: AXUIElement?
        var bestArea = Double.greatestFiniteMagnitude
        for k in kids {
            guard frameContains(k, pt), let f = axFrame(k) else { continue }
            let area = f.width * f.height
            if area < bestArea { bestArea = area; next = k }
        }
        guard let n = next, CFEqual(n, cur) == false else { break }
        best = n
        cur = n
    }
    return best
}

// Roles that carry a window's actual content. AXWindow/AXGroup are excluded because
// Chromium and Electron expose their whole web view as one AXGroup, and AXButton is
// excluded because the three titlebar buttons are always present even in an app that
// exposes nothing. So a tree with none of these is opaque, not merely shallow.
let CONTENT_ROLES: Set<String> = [
    "AXStaticText", "AXTextField", "AXTextArea", "AXLink", "AXCell", "AXRow",
    "AXOutline", "AXTable", "AXList", "AXImage", "AXCheckBox", "AXRadioButton",
    "AXMenuButton", "AXPopUpButton", "AXComboBox", "AXSlider", "AXTabGroup",
    "AXIncrementor", "AXStepper", "AXDisclosureTriangle", "AXBusyIndicator",
    "AXProgressIndicator", "AXLevelIndicator", "AXValueIndicator", "AXColorWell",
    "AXDateField", "AXRatingIndicator", "AXHeading",
]

func tallyRoles(_ node: [String: Any], _ counts: inout [String: Int]) {
    if let r = node["role"] as? String { counts[r, default: 0] += 1 }
    if let kids = node["children"] as? [[String: Any]] {
        for k in kids { tallyRoles(k, &counts) }
    }
}

// `truncated` matters: content roles can sit below the node budget, so a cut tree
// with no content roles found is NOT evidence of opacity. Claiming it is would tell an
// agent its view is complete-and-empty when the truth is "we stopped looking".
func opacityReport(_ roots: [[String: Any]], truncated: Bool) -> [String: Any] {
    var counts: [String: Int] = [:]
    for r in roots { tallyRoles(r, &counts) }
    let content = counts.filter { CONTENT_ROLES.contains($0.key) }.values.reduce(0, +)
    var out: [String: Any] = [
        "roleCounts": counts,
        "contentNodes": content,
    ]
    if truncated {
        out["looksOpaque"] = NSNull()
        out["opacityReason"] = "truncated"
        out["hint"] = "No content elements were found, but the tree was cut off by the "
            + "node limit, so this is inconclusive. Raise 'max' and read again before "
            + "concluding anything about this app."
    } else if roots.isEmpty {
        out["looksOpaque"] = NSNull()
        out["opacityReason"] = "no-windows"
        out["hint"] = "No on-screen windows were returned for this app, so there was "
            + "nothing to inspect."
    } else if content == 0 {
        out["looksOpaque"] = true
        out["opacityReason"] = "no-content-roles"
        out["hint"] = "No content-bearing roles (text fields, rows, cells, images) were "
            + "found in this app's window. The usual cause is a Chromium/Electron app "
            + "that does not bridge its web contents, so the whole UI is one or more "
            + "AXGroup nodes. It can also mean the UI is built only from buttons and "
            + "controls, which this check does not count. If reads look empty, confirm "
            + "with computer_screenshot; fall back to coordinates or computer_applescript."
    } else {
        out["looksOpaque"] = false
        out["opacityReason"] = "content-present"
    }
    return out
}

func findApp(query: String) -> NSRunningApplication? {
    let running = NSWorkspace.shared.runningApplications.filter {
        $0.activationPolicy == .regular && !$0.isTerminated
    }
    if let byPid = Int(query), let app = running.first(where: { $0.processIdentifier == byPid }) {
        return app
    }
    let q = query.lowercased()
    return running.first { $0.bundleIdentifier?.lowercased() == q }
        ?? running.first { $0.localizedName?.lowercased() == q }
        ?? running.first { $0.localizedName?.lowercased().contains(q) ?? false }
        ?? running.first { $0.bundleIdentifier?.lowercased().contains(q) ?? false }
}

func resolveAXApp() -> (AXUIElement, String, pid_t) {
    if let q = args.flags["app"] {
        guard let app = findApp(query: q) else { fail("no running app matching '\(q)'") }
        return (AXUIElementCreateApplication(app.processIdentifier), app.localizedName ?? q, app.processIdentifier)
    }
    guard let front = NSWorkspace.shared.frontmostApplication else { fail("could not determine frontmost app") }
    return (AXUIElementCreateApplication(front.processIdentifier), front.localizedName ?? "frontmost", front.processIdentifier)
}

// Topmost on-screen window covering a point. CGWindowList is front-to-back, so the
// first match is the window that would receive a click there.
//
// Deliberately NOT restricted to layer 0: alerts, popovers and floating panels live
// above it, and a click over one of those lands on it, not on the window behind.
// Only obviously non-interactive helper rects are skipped.
func topmostWindow(at pt: CGPoint) -> (pid: pid_t, frame: CGRect)? {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
    else { return nil }
    for w in list {
        let layer = (w[kCGWindowLayer as String] as? Int) ?? 0
        // Only normal application windows, at layer 0. Anything higher is transient
        // system UI, and the Dock is the dangerous one: it owns a full-screen window
        // covering every display at layer 20, and CGWindowList puts it ahead of every
        // app window. Accepting it made topmostWindow return the Dock for any point on
        // screen, the Dock has no AXWindow children, so the descent was skipped
        // everywhere and every result silently fell back to the OS hit test.
        guard layer == 0 else { continue }
        let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
        let x = (b["X"] as? Double) ?? 0, y = (b["Y"] as? Double) ?? 0
        let ww = (b["Width"] as? Double) ?? 0, wh = (b["Height"] as? Double) ?? 0
        guard ww >= MIN_TRACKED_WINDOW, wh >= MIN_TRACKED_WINDOW else { continue }
        guard pt.x >= x, pt.y >= y, pt.x < x + ww, pt.y < y + wh else { continue }
        guard let pid = w[kCGWindowOwnerPID as String] as? pid_t else { continue }
        return (pid, CGRect(x: x, y: y, width: ww, height: wh))
    }
    return nil
}

// Electron caches AX frames, so right after a window moves the tree can still report
// the old window rect. Poll until AX agrees with the window server, so callers do not
// act on a stale window origin.
//
// This compares WINDOW-level rects only, because the window server does not know
// about child elements. A resize where the window frame is already current but its
// children are not is therefore not detected here. Returns (settled, waitedMs).
func axSettle(pid: pid_t, timeoutMs: Int) -> (Bool, Int) {
    let step = 120
    var waited = 0
    while true {
        if axAgreesWithWindowServer(pid: pid) { return (true, waited) }
        if waited + step > timeoutMs { return (false, waited) }
        usleep(useconds_t(step * 1000))
        waited += step
    }
}

// nil means no check ran (no window at the point, or settling disabled). Callers must
// not report that as "settled".
func axSettleOrSkip(pid: pid_t?, timeoutMs: Int, skip: Bool) -> (Bool?, Int) {
    if skip { return (nil, 0) }
    guard let pid = pid else { return (nil, 0) }
    let (ok, waited) = axSettle(pid: pid, timeoutMs: timeoutMs)
    return (ok, waited)
}

// Every server frame must be matched by some AX window frame, within tolerance.
// Order and count differ between the two sources, so this is a set comparison.
func framesAgree(_ server: [CGRect], _ axFrames: [CGRect], tol: CGFloat = 2) -> Bool {
    for f in server {
        let matched = axFrames.contains { a in
            abs(a.minX - f.minX) <= tol && abs(a.minY - f.minY) <= tol
                && abs(a.width - f.width) <= tol && abs(a.height - f.height) <= tol
        }
        if !matched { return false }
    }
    return true
}

// Window-server rects worth comparing. Small helper windows (Chromium infobubbles,
// drag images, tooltips) routinely have no AX counterpart, and treating those as
// staleness would burn the whole timeout on every call for those apps.
let MIN_TRACKED_WINDOW: CGFloat = 40

func serverFrames(pid: pid_t, minSize: CGFloat = MIN_TRACKED_WINDOW) -> [CGRect] {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
    else { return [] }
    var out: [CGRect] = []
    for w in list where (w[kCGWindowLayer as String] as? Int ?? 0) == 0 {
        guard (w[kCGWindowOwnerPID as String] as? pid_t) == pid else { continue }
        let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
        guard let x = b["X"] as? Double, let y = b["Y"] as? Double,
              let ww = b["Width"] as? Double, let wh = b["Height"] as? Double else { continue }
        guard ww >= minSize, wh >= minSize else { continue }
        out.append(CGRect(x: x, y: y, width: ww, height: wh))
    }
    return out
}

func axWindowFrames(pid: pid_t) -> [CGRect] {
    let appEl = AXUIElementCreateApplication(pid)
    var out: [CGRect] = []
    for w in (axChildren(appEl) ?? []) where axString(w, kAXRoleAttribute as String) == (kAXWindowRole as String) {
        if let f = axFrame(w) { out.append(f) }
    }
    return out
}

func axAgreesWithWindowServer(pid: pid_t) -> Bool {
    let server = serverFrames(pid: pid)
    if server.isEmpty { return true }
    let axF = axWindowFrames(pid: pid)
    if axF.isEmpty { return true }
    return framesAgree(server, axF)
}

// MARK: - Input helpers

var modFlags: CGEventFlags = []
var activeModifiers: Set<String> = []

func setModifiers(_ spec: String?) {
    activeModifiers = []
    modFlags = []
    guard let spec, !spec.isEmpty else { return }
    for part in spec.split(separator: ",").map({ $0.lowercased().trimmingCharacters(in: .whitespaces) }) {
        switch part {
        case "cmd", "command", "meta": modFlags.insert(.maskCommand); activeModifiers.insert("cmd")
        case "shift": modFlags.insert(.maskShift); activeModifiers.insert("shift")
        case "alt", "option": modFlags.insert(.maskAlternate); activeModifiers.insert("alt")
        case "ctrl", "control": modFlags.insert(.maskControl); activeModifiers.insert("ctrl")
        default: fail("unknown modifier '\(part)' (use cmd, shift, alt, ctrl)")
        }
    }
}

let keyMap: [String: UInt16] = [
    "return": 0x24, "enter": 0x24, "tab": 0x30, "space": 0x31, "delete": 0x33,
    "backspace": 0x33, "escape": 0x35, "esc": 0x35, "forwarddelete": 0x75,
    "up": 0x7E, "down": 0x7D, "left": 0x7B, "right": 0x7C,
    "home": 0x73, "end": 0x77, "pageup": 0x74, "pagedown": 0x79,
    "cmd": 0x37, "command": 0x37, "shift": 0x38, "alt": 0x3A, "option": 0x3A,
    "ctrl": 0x3B, "control": 0x3B, "capslock": 0x39, "fn": 0x63,
    "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76, "f5": 0x60, "f6": 0x61,
    "f7": 0x62, "f8": 0x64, "f9": 0x65, "f10": 0x6D, "f11": 0x67, "f12": 0x6F,
    "f13": 0x69, "f14": 0x6B, "f15": 0x71,
    "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06,
    "x": 0x07, "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E,
    "r": 0x0F, "y": 0x10, "t": 0x11, "o": 0x1F, "u": 0x20, "i": 0x22, "p": 0x23,
    "l": 0x25, "j": 0x26, "k": 0x28, "n": 0x2D, "m": 0x2E,
    "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "5": 0x17, "6": 0x16, "7": 0x1A,
    "8": 0x1C, "9": 0x19, "0": 0x1D, "-": 0x1B, "=": 0x18, "[": 0x21, "]": 0x1E,
    ";": 0x29, "'": 0x27, ",": 0x2B, ".": 0x2F, "/": 0x2C, "\\": 0x2A, "`": 0x32,
]

func resolveKeycode(_ name: String) -> UInt16 {
    if let kc = keyMap[name.lowercased()] { return kc }
    if let kc = UInt16(name) { return kc }
    fail("unknown key '\(name)' — use a key name (return, tab, escape, up, cmd+a style names) or a numeric virtual keycode")
}

func postKey(_ keycode: UInt16, flags: CGEventFlags, down: Bool) {
    let ev = CGEvent(keyboardEventSource: SRC, virtualKey: keycode, keyDown: down)!
    ev.flags = flags
    ev.post(tap: .cghidEventTap)
}

func moveCursor(to pt: CGPoint) {
    let move = CGEvent(mouseEventSource: SRC, mouseType: .mouseMoved,
                       mouseCursorPosition: pt, mouseButton: .left)!
    move.post(tap: .cghidEventTap)
    usleep(40_000)
}

// MARK: - Screenshot helper

// The capture target as screen points, so the captured pixels can be scaled back to
// the point space that click/axpoint/ax use. nil means "keep native pixels".
func targetDisplay() -> NSScreen? {
    if let d = args.flags["display"], let i = Int(d), NSScreen.screens.indices.contains(i) {
        return NSScreen.screens[i]
    }
    if NSScreen.screens.count == 1 { return NSScreen.main }
    // Multiple displays: screencapture spans all of them, so the union is the target.
    return nil
}

func unionScreenFrame() -> CGRect? {
    guard NSScreen.screens.count > 1 else { return nil }
    var u = CGRect.null
    for s in NSScreen.screens { u = u.union(s.frame) }
    return u.isEmpty ? nil : u
}

// Shrink only. Callers must not ask to grow.
func resample(_ path: String, to targetW: Int, _ targetH: Int, from w0: Int, _ h0: Int) {
    let conv = Process()
    conv.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    if w0 > targetW && h0 > targetH {
        conv.arguments = ["-Z", String(max(targetW, targetH)), path]
    } else {
        conv.arguments = ["--resampleHeightWidth", String(targetH), String(targetW), path]
    }
    conv.standardOutput = Pipe(); conv.standardError = Pipe()
    try? conv.run()
    conv.waitUntilExit()
}

func imageDims(_ path: String) -> (Int, Int)? {
    guard let src = CGImageSourceCreateWithURL(CFURLCreateWithFileSystemPath(nil, path as CFString, .cfurlposixPathStyle, false), nil),
          let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
          let w = props[kCGImagePropertyPixelWidth] as? Int,
          let h = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
    return (w, h)
}

// MARK: - Command implementations

switch cmd {

case "perms":
    let prompt = args.has.contains("prompt")
    let ax = AXIsProcessTrusted()
    let screen = CGPreflightScreenCaptureAccess()
    if prompt && !ax {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
    if prompt && !screen {
        _ = CGRequestScreenCaptureAccess()
    }
    emit([
        "accessibility": ax,
        "screenRecording": screen,
        "note": !ax || !screen
            ? "Grant missing permissions in System Settings > Privacy & Security to the app that hosts this process (e.g. Terminal, iTerm, VS Code), then restart it."
            : "all granted",
    ])

case "screeninfo":
    var screens: [[String: Any]] = []
    for (i, s) in NSScreen.screens.enumerated() {
        let f = s.frame
        screens.append([
            "index": i,
            "displayId": s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int ?? 0,
            "isMain": s == NSScreen.main,
            "x": f.origin.x, "y": f.origin.y,
            "width": f.width, "height": f.height,
        ])
    }
    emit(["screens": screens])

case "screenshot":
    guard let out = args.flags["out"] else { fail("--out <path> required") }
    let png = args.has.contains("png")
    // Capture losslessly and only encode once, at the end. Capturing JPEG then
    // resampling re-encodes through sips, so every Retina capture took two lossy
    // passes, which is what hurts small text.
    let captureAsPng = true
    var argv = ["/usr/sbin/screencapture", "-x", captureAsPng ? "-tpng" : "-tjpeg"]
    if let r = args.flags["region"] {
        let parts = r.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4 else { fail("--region must be x,y,w,h") }
        argv.append("-R\(Int(parts[0])),\(Int(parts[1])),\(Int(parts[2])),\(Int(parts[3]))")
    }
    if let d = args.flags["display"], let i = Int(d) {
        // screeninfo reports a 0-based index; screencapture -D is 1-based and
        // documents "1 is main". Passing our index straight through captured the
        // wrong display and scaled to the wrong point width.
        argv.append("-D\(max(1, i + 1))")
    }
    if let w = args.flags["window"] { argv.append("-l\(w)") }
    argv.append(out)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: argv[0])
    p.arguments = Array(argv.dropFirst())
    try? p.run()
    p.waitUntilExit()
    guard p.terminationStatus == 0 else { fail("screencapture exited \(p.terminationStatus); screen recording permission may be missing") }
    guard FileManager.default.fileExists(atPath: out) else { fail("screenshot file was not created") }

    // Screencapture emits native device pixels (Retina: 2x the point size), while
    // click/axpoint take screen points. Scale DOWN to the point size by default so
    // image pixels and screen points are the same units, which is what the tools
    // promise. --full-res keeps native pixels and is independent of --png.
    var pointW: Int? = nil
    if let d = args.flags["region"] {
        let parts = d.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if parts.count == 4, parts[2] > 0 { pointW = Int(parts[2]) }
    } else if let target = targetDisplay()?.frame ?? unionScreenFrame(), Int(target.width) > 0 {
        pointW = Int(target.width)
    }

    // Only ever shrink. A region running off the edge of a display is captured
    // smaller than asked for; stretching it back up would invent detail and then
    // report scale 1, which is a lie.
    if !args.has.contains("full-res"), let pw = pointW,
       let (w0, h0) = imageDims(out), pw > 0, w0 > pw {
        // Derive height from the point aspect so we do not distort a region capture.
        let ph = Int((Double(h0) / Double(w0) * Double(pw)).rounded())
        resample(out, to: pw, ph, from: w0, h0)
    }

    // Single encode, now that the pixels are final.
    if !png {
        let conv = Process()
        conv.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        conv.arguments = ["-s", "format", "jpeg", out]
        conv.standardOutput = Pipe(); conv.standardError = Pipe()
        try? conv.run()
        conv.waitUntilExit()
    }

    var node: [String: Any] = ["path": out, "format": png ? "png" : "jpeg"]
    if let (w, h) = imageDims(out) {
        node["width"] = w
        node["height"] = h
        // Image pixels per screen point, measured on the FINAL image so callers can
        // convert coordinates they read off it. 1 means the image is point-matched.
        if let pw = pointW, pw > 0 {
            node["scale"] = Double(w) / Double(pw)
        } else {
            node["scale"] = Double(NSScreen.main?.backingScaleFactor ?? 1)
        }
        // A whole-screen capture on a multi-display setup spans the union of all
        // displays, so image pixel (0,0) is not global (0,0). Say so, otherwise the
        // point-matched promise looks trustworthy while being offset.
        if let d = args.flags["region"] {
            let parts = d.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count == 4 {
                node["origin"] = [Int(parts[0]), Int(parts[1])]
            }
        } else if let u = unionScreenFrame() {
            node["origin"] = [Int(u.minX), Int(u.minY)]
            node["coversAllDisplays"] = NSScreen.screens.count > 1
        }
    }
    emit(node)

case "cursor":
    let loc = CGEvent(source: nil)?.location ?? .zero
    emit(["x": Int(loc.x), "y": Int(loc.y)])

case "move":
    guard rest.count == 2, let x = Double(rest[0]), let y = Double(rest[1]) else {
        fail("usage: computeruse move <x> <y>")
    }
    moveCursor(to: CGPoint(x: x, y: y))
    emit(["x": Int(x), "y": Int(y)])

case "click":
    let x = doubleFlag("x", -1), y = doubleFlag("y", -1)
    let count = intFlag("count", 1)
    let button = (args.flags["button"] ?? "left").lowercased()
    let cgButton: CGMouseButton
    let downType: CGEventType, upType: CGEventType
    switch button {
    case "left": cgButton = .left; downType = .leftMouseDown; upType = .leftMouseUp
    case "right": cgButton = .right; downType = .rightMouseDown; upType = .rightMouseUp
    case "middle": cgButton = .center; downType = .otherMouseDown; upType = .otherMouseUp
    default: fail("--button must be left, right, or middle")
    }
    guard count >= 1 && count <= 3 else { fail("--count must be 1-3") }
    if x >= 0 && y >= 0 { moveCursor(to: CGPoint(x: x, y: y)) }
    let pt = CGEvent(source: nil)?.location ?? .zero
    for clickIndex in 1...count {
        let down = CGEvent(mouseEventSource: SRC, mouseType: downType,
                           mouseCursorPosition: pt, mouseButton: cgButton)!
        down.setIntegerValueField(.mouseEventClickState, value: Int64(clickIndex))
        down.post(tap: .cghidEventTap)
        usleep(60_000)
        let up = CGEvent(mouseEventSource: SRC, mouseType: upType,
                         mouseCursorPosition: pt, mouseButton: cgButton)!
        up.setIntegerValueField(.mouseEventClickState, value: Int64(clickIndex))
        up.post(tap: .cghidEventTap)
        usleep(120_000)
    }
    emit(["x": Int(pt.x), "y": Int(pt.y), "button": button, "count": count])

case "drag":
    guard rest.count == 4,
          let x1 = Double(rest[0]), let y1 = Double(rest[1]),
          let x2 = Double(rest[2]), let y2 = Double(rest[3]) else {
        fail("usage: computeruse drag <x1> <y1> <x2> <y2>")
    }
    let ms = intFlag("ms", 400)
    moveCursor(to: CGPoint(x: x1, y: y1))
    let down = CGEvent(mouseEventSource: SRC, mouseType: .leftMouseDown,
                       mouseCursorPosition: CGPoint(x: x1, y: y1), mouseButton: .left)!
    down.post(tap: .cghidEventTap)
    usleep(80_000)
    let steps = max(8, ms / 10)
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        let px = x1 + (x2 - x1) * t
        let py = y1 + (y2 - y1) * t
        let mv = CGEvent(mouseEventSource: SRC, mouseType: .leftMouseDragged,
                         mouseCursorPosition: CGPoint(x: px, y: py), mouseButton: .left)!
        mv.post(tap: .cghidEventTap)
        usleep(useconds_t(max(1000, ms * 1000 / steps)))
    }
    let up = CGEvent(mouseEventSource: SRC, mouseType: .leftMouseUp,
                     mouseCursorPosition: CGPoint(x: x2, y: y2), mouseButton: .left)!
    up.post(tap: .cghidEventTap)
    emit(["from": [Int(x1), Int(y1)], "to": [Int(x2), Int(y2)]])

case "scroll":
    let dx = intFlag("dx", 0), dy = intFlag("dy", 0)
    if let x = args.flags["x"], let y = args.flags["y"],
       let px = Double(x), let py = Double(y) {
        moveCursor(to: CGPoint(x: px, y: py))
    }
    guard dx != 0 || dy != 0 else { fail("nothing to scroll: set --dy or --dx") }
    // dy > 0 means scroll down, dx > 0 means scroll right
    let ev = CGEvent(scrollWheelEvent2Source: SRC, units: .line, wheelCount: dx != 0 ? 2 : 1,
                     wheel1: -Int32(dy), wheel2: -Int32(dx), wheel3: 0)!
    ev.post(tap: .cghidEventTap)
    usleep(50_000)
    emit(["dx": dx, "dy": dy])

case "type":
    var text = ""
    if args.has.contains("stdin") {
        text = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
    } else if let t = args.flags["text"] {
        text = t
    } else if !rest.isEmpty {
        text = rest.joined(separator: " ")
    }
    guard !text.isEmpty else { fail("no text to type") }
    let delayUs = useconds_t(max(0, doubleFlag("delay", 8) * 1000))
    for ch in text {
        if ch == "\n" { postKey(0x24, flags: [], down: true); usleep(20_000); postKey(0x24, flags: [], down: false); usleep(delayUs); continue }
        if ch == "\t" { postKey(0x30, flags: [], down: true); usleep(20_000); postKey(0x30, flags: [], down: false); usleep(delayUs); continue }
        var utf = Array(String(ch).utf16)
        let down = CGEvent(keyboardEventSource: SRC, virtualKey: 0, keyDown: true)!
        down.keyboardSetUnicodeString(stringLength: utf.count, unicodeString: &utf)
        down.post(tap: .cghidEventTap)
        usleep(10_000)
        let up = CGEvent(keyboardEventSource: SRC, virtualKey: 0, keyDown: false)!
        up.keyboardSetUnicodeString(stringLength: utf.count, unicodeString: &utf)
        up.post(tap: .cghidEventTap)
        usleep(delayUs)
    }
    emit(["typed": text.count])

case "key":
    guard let keyName = rest.first else { fail("usage: computeruse key <name> [--mod cmd,shift]") }
    setModifiers(args.flags["mod"] ?? args.flags["modifiers"])
    let repeatCount = intFlag("repeat", 1)
    let kc = resolveKeycode(keyName)
    for _ in 0..<repeatCount {
        postKey(kc, flags: modFlags, down: true)
        usleep(30_000)
        postKey(kc, flags: modFlags, down: false)
        usleep(60_000)
    }
    emit(["key": keyName, "modifiers": Array(activeModifiers).sorted(), "repeat": repeatCount])

case "apps":
    var list: [[String: Any]] = []
    for app in NSWorkspace.shared.runningApplications
        .filter({ $0.activationPolicy == .regular && !$0.isTerminated })
        .sorted(by: { ($0.localizedName ?? "") < ($1.localizedName ?? "") }) {
        list.append([
            "pid": app.processIdentifier,
            "name": app.localizedName ?? "",
            "bundleId": app.bundleIdentifier ?? "",
            "frontmost": app == NSWorkspace.shared.frontmostApplication,
            "hidden": app.isHidden,
        ])
    }
    emit(["apps": list])

case "frontapp":
    guard let f = NSWorkspace.shared.frontmostApplication else { fail("no frontmost app") }
    emit(["pid": f.processIdentifier, "name": f.localizedName ?? "", "bundleId": f.bundleIdentifier ?? ""])

case "launch":
    guard let name = rest.first else { fail("usage: computeruse launch <app name or bundle id>") }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = [name.contains(".") ? "-b" : "-a", name]
    let errPipe = Pipe()
    p.standardError = errPipe
    p.standardOutput = Pipe()
    do { try p.run() } catch { fail("could not launch: \(error.localizedDescription)") }
    p.waitUntilExit()
    guard p.terminationStatus == 0 else {
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        fail("launch failed: \(err.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    var found: NSRunningApplication?
    for _ in 0..<50 {
        found = findApp(query: name)
        if found != nil { break }
        usleep(100_000)
    }
    if let f = found {
        emit(["launched": true, "pid": f.processIdentifier, "name": f.localizedName ?? "", "bundleId": f.bundleIdentifier ?? ""])
    } else {
        emit(["launched": true, "pid": NSNull(), "name": name, "bundleId": NSNull()])
    }

case "activate":
    guard let name = rest.first, let app = findApp(query: name) else { fail("no running app matching '\(rest.first ?? "")'") }
    app.activate(options: [.activateAllWindows])
    usleep(200_000)
    // activateAllWindows can still leave a window flagged minimized. Pass --clamp to
    // also pull windows that are mostly off the displays back into view.
    let repairs = repairWindows(pid: app.processIdentifier, clamp: args.has.contains("clamp"))
    emit(["activated": app.localizedName ?? "", "repaired": repairs])

case "quit":
    guard let name = rest.first, let app = findApp(query: name) else { fail("no running app matching '\(rest.first ?? "")'") }
    let ok = app.terminate()
    usleep(300_000)
    emit(["quit": app.localizedName ?? "", "requested": ok])

case "windows":
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
        fail("could not list windows; screen recording permission may be missing")
    }
    let appFilter = args.flags["app"]?.lowercased()
    let layer = intFlag("layer", 0)
    var out: [[String: Any]] = []
    for w in list {
        let l = (w[kCGWindowLayer as String] as? Int) ?? 0
        if l != layer { continue }
        let owner = (w[kCGWindowOwnerName as String] as? String) ?? ""
        if let f = appFilter, !owner.lowercased().contains(f) { continue }
        let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
        let x = (b["X"] as? Double) ?? 0, y = (b["Y"] as? Double) ?? 0
        let wd = (b["Width"] as? Double) ?? 0, ht = (b["Height"] as? Double) ?? 0
        if wd < 40 || ht < 40 { continue }
        var item: [String: Any] = [
            "windowId": w[kCGWindowNumber as String] as? Int ?? 0,
            "pid": w[kCGWindowOwnerPID as String] as? Int ?? 0,
            "app": owner,
            "x": Int(x), "y": Int(y), "width": Int(wd), "height": Int(ht),
            "layer": l,
        ]
        if let t = w[kCGWindowName as String] as? String { item["title"] = t }
        out.append(item)
    }
    emit(["windows": out])

case "ax":
    let (el, appName, pid) = resolveAXApp()
    let maxDepth = intFlag("depth", 14)
    resetNodeBudget(intFlag("max", 600))
    let (settled, waitedMs) = axSettleOrSkip(
        pid: pid, timeoutMs: intFlag("settle", 1200), skip: args.has.contains("no-wait")
    )
    var out: [String: Any] = [
        "app": appName,
        "nodeLimit": nodeBudgetMax,
        "axSettled": settled ?? NSNull(),
        "settleWaitedMs": waitedMs,
    ]
    if args.has.contains("full") {
        let tree = axNode(el, depth: 0, maxDepth: maxDepth)
        out["tree"] = tree
        out["nodes"] = nodesVisited
        out["truncated"] = nodeBudget <= 0
        for (k, v) in opacityReport([tree], truncated: nodeBudget <= 0) { out[k] = v }
    } else if let windows = axChildren(el) {
        var list: [[String: Any]] = []
        for w in windows where nodeBudget > 0 {
            list.append(axNode(w, depth: 1, maxDepth: maxDepth))
        }
        out["windows"] = list
        out["nodes"] = nodesVisited
        out["truncated"] = nodeBudget <= 0
        for (k, v) in opacityReport(list, truncated: nodeBudget <= 0) { out[k] = v }
    } else {
        fail("no windows found for '\(appName)' (app may be launching or has no on-screen windows)")
    }
    emit(out)

case "axpoint":
    guard rest.count == 2, let x = Double(rest[0]), let y = Double(rest[1]) else {
        fail("usage: computeruse axpoint <x> <y>")
    }
    let pt = CGPoint(x: x, y: y)
    resetNodeBudget(120)

    // Never resolve against a stale tree: a wrong frame here means clicking the
    // wrong thing, which is the one mistake an agent cannot easily notice.
    // Look the window up ONCE. Two reads can disagree if the window manager re-tiles
    // in between, which would settle one app and then descend into another.
    let top = topmostWindow(at: pt)
    let (settled, waitedMs) = axSettleOrSkip(
        pid: top?.pid, timeoutMs: intFlag("settle", 1200), skip: args.has.contains("no-wait")
    )

    // Reference answer straight from the OS, kept for comparison.
    var hittestRole = "none"
    var hittest: AXUIElement?
    let sysEl = AXUIElementCreateSystemWide()
    if AXUIElementCopyElementAtPosition(sysEl, Float(x), Float(y), &hittest) == .success, let h = hittest {
        hittestRole = axString(h, kAXRoleAttribute as String) ?? "unknown"
    }

    // Our answer: descend from that window. Filter to AXWindow so we never walk into
    // the menu bar, matching every other AX walk in this file.
    var chosen: AXUIElement?
    if let t = top {
        let appEl = AXUIElementCreateApplication(t.pid)
        for win in (axChildren(appEl) ?? [])
        where axString(win, kAXRoleAttribute as String) == (kAXWindowRole as String)
            && frameContains(win, pt) {
            chosen = deepestLeaf(win, pt)
            break
        }
    }

    let el = chosen ?? hittest
    guard let target = el else {
        fail("no accessibility element at (\(Int(x)), \(Int(y)))")
    }
    let role = axString(target, kAXRoleAttribute as String) ?? "unknown"
    emit([
        "x": Int(x), "y": Int(y),
        "role": role,
        "source": chosen != nil ? "descend" : "hittest",
        // Set when the OS hit test disagrees with our descent. On Chromium/Electron
        // windows the OS reports the web-content group while the click lands on a
        // native control on top of it; this flag marks that case.
        "osHitTestDiffers": hittestRole != role,
        "osHitTestRole": hittestRole,
        // null means no settle check ran. false means the tree never caught up with
        // the window server, so this result may reflect stale frames.
        "axSettled": settled ?? NSNull(),
        "settleWaitedMs": waitedMs,
        "node": axNode(target, depth: 0, maxDepth: 2),
    ])

// Diagnostic: read the window server and the AX tree back to back in one process and
// report whether they agree. Separate processes can be interleaved by the window
// manager, which makes the comparison meaningless.
case "axsync":
    // Self-test runs the real comparison against synthetic frames, which is the only
    // way to prove the matcher here: a tiling window manager snaps windows back so
    // fast that an external move never leaves a disagreement to observe.
    if args.has.contains("selftest") {
        var cases: [[String: Any]] = []
        let r = CGRect(x: 24, y: 24, width: 1872, height: 1031)
        let stale = CGRect(x: 150, y: 110, width: 1872, height: 1031)
        let nudge = CGRect(x: 25, y: 24, width: 1872, height: 1031)
        let resized = CGRect(x: 24, y: 24, width: 1872, height: 900)
        for (name, server, axF, want) in [
            ("identical", [r], [r], true),
            ("stale AX position", [r], [stale], false),
            ("stale AX size", [r], [resized], false),
            ("within tolerance", [r], [nudge], true),
            ("AX has no windows", [r], [], false),
            ("one of two AX windows stale", [r, stale], [r], false),
            ("same set, different order", [r, stale], [stale, r], true),
            ("AX has extra window", [r], [r, stale], true),
        ] {
            let got = framesAgree(server, axF)
            cases.append([
                "case": name, "expected": want, "got": got, "pass": got == want,
            ])
        }
        let passed = cases.allSatisfy { ($0["pass"] as? Bool) == true }
        emit(["selftest": true, "passed": passed, "cases": cases])
        // Nonzero on failure so `set -e` and CI do not read a red self-test as green.
        exit(passed ? 0 : 1)
    }

    let (_, appName, pid) = resolveAXApp()

    // Reuse the production walks so this cannot drift from what axAgreesWithWindowServer
    // actually compares. Truncating to Int here while framesAgree uses a 2pt tolerance
    // made before/after able to disagree with the verdict by a point.
    func snapshot() -> ([[String: Any]], [[String: Any]]) {
        let fmt: (CGRect) -> [String: Any] = { f in
            [
                "pos": [Double(f.minX), Double(f.minY)],
                "size": [Double(f.width), Double(f.height)],
            ]
        }
        return (serverFrames(pid: pid).map(fmt), axWindowFrames(pid: pid).map(fmt))
    }

    let before = snapshot()
    let initiallyAgrees = axAgreesWithWindowServer(pid: pid)
    let (settled, waited) = axSettleOrSkip(
        pid: pid, timeoutMs: intFlag("settle", 1200), skip: args.has.contains("no-wait")
    )
    // Re-read after waiting, otherwise this reports the stale frames it just fixed.
    let after = snapshot()
    emit([
        "app": appName,
        "before": ["windowServer": before.0, "accessibilityTree": before.1],
        "after": ["windowServer": after.0, "accessibilityTree": after.1],
        "initiallyAgrees": initiallyAgrees,
        // null means no settle check ran.
        "agrees": settled ?? NSNull(),
        "waitedMs": waited,
    ])

case "menu":
    guard rest.count >= 2 else { fail("usage: computeruse menu <app> <Item1> [Item2] ...") }
    guard let app = findApp(query: rest[0]) else { fail("no running app matching '\(rest[0])'") }
    let items = Array(rest.dropFirst())
    // Build a System Events click expression for the nested path, e.g.
    // click menu item "New" of menu 1 of menu bar item "File" of menu bar 1
    func esc(_ s: String) -> String { s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") }
    var ref = "menu bar item \"\(esc(items[0]))\" of menu bar 1"
    for item in items.dropFirst() {
        ref = "menu item \"\(esc(item))\" of menu 1 of \(ref)"
    }
    let script = """
    tell application "System Events"
      tell (first application process whose unix id is \(app.processIdentifier))
        click \(ref)
      end tell
    end tell
    """
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    p.arguments = ["-e", script]
    let errPipe = Pipe()
    p.standardError = errPipe
    p.standardOutput = Pipe()
    do { try p.run() } catch { fail("could not run osascript: \(error.localizedDescription)") }
    p.waitUntilExit()
    guard p.terminationStatus == 0 else {
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        fail("menu click failed: \(err.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    emit(["app": app.localizedName ?? "", "menuPath": items])

default:
    fail("unknown command '\(cmd)'. Valid: perms, screeninfo, screenshot, cursor, move, click, drag, scroll, type, key, apps, frontapp, launch, activate, quit, windows, ax, axsync, axpoint, menu")
}
