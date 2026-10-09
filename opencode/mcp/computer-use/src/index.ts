#!/usr/bin/env node
// opencode-computer-use MCP server — gives opencode control of macOS:
// screenshots, mouse, keyboard, accessibility tree, app/window management.
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import type { CallToolResult } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, readFile, rmdir, unlink } from "node:fs/promises";
import { dirname } from "node:path";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const execFileP = promisify(execFile);
const BIN = fileURLToPath(new URL("../bin/computeruse", import.meta.url));

const PERM_HINT =
  "If this failed with a permissions error: open System Settings > Privacy & Security > " +
  "Accessibility (and Screen Recording) and enable the app hosting this MCP server " +
  "(e.g. Terminal, iTerm, VS Code), then restart that app. Run computer_permissions to verify.";

interface ShotMeta {
	path: string;
	format: "png" | "jpeg";
	width: number;
	height: number;
	scale: number;
	origin?: [number, number];
	coversAllDisplays?: boolean;
}

async function runCli(args: string[], timeoutMs = 30_000) {
  try {
    const { stdout } = await execFileP(BIN, args, { timeout: timeoutMs, maxBuffer: 64 * 1024 * 1024 });
    return stdout;
  } catch (err) {
    const e = err as { code?: string };
    // A missing binary is not a permissions problem. Reporting it as one sends people
    // into System Settings to grant access they already have.
    if (e.code === "ENOENT") {
      throw new Error(
        `The macOS helper binary is missing:\n  ${BIN}\n\n` +
          `It lives next to this server's dist/ directory. Rebuild it with:\n` +
          `  cd ${dirname(dirname(BIN))} && npm run build\n\n` +
          `If the server was moved or deleted after it started, restart the host app so ` +
          `it re-reads its configured path.`,
      );
    }
    throw new Error(`${errText(err)}\n\n${PERM_HINT}`);
  }
}

function errText(err: unknown): string {
  const e = err as { stderr?: string; message?: string };
  return (e.stderr || e.message || String(err)).trim();
}

function runOsascript(code: string, timeoutMs = 60_000): Promise<string> {
  return new Promise((resolve, reject) => {
    const p = spawn("/usr/bin/osascript", ["-"], { stdio: ["pipe", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      p.kill("SIGKILL");
      reject(new Error("osascript timed out"));
    }, timeoutMs);
    p.stdout.on("data", (d) => (stdout += d));
    p.stderr.on("data", (d) => (stderr += d));
    p.on("error", (e) => { clearTimeout(timer); reject(e); });
    p.on("close", (codeNum) => {
      clearTimeout(timer);
      if (codeNum === 0) resolve(stdout.trim() || "(no output)");
      else reject(new Error(stderr.trim() || `osascript exited with ${codeNum}`));
    });
    p.stdin.write(code);
    p.stdin.end();
  });
}

function jsonOut(text: string): CallToolResult {
  return { content: [{ type: "text", text }] };
}

function errOut(text: string): CallToolResult {
  return { content: [{ type: "text", text }], isError: true };
}

function fmt(result: unknown): CallToolResult {
  return jsonOut(typeof result === "string" ? result : JSON.stringify(result, null, 2));
}

const server = new McpServer({
  name: "opencode-computer-use",
  version: "1.0.0",
});

// ---------- permissions ----------

server.registerTool(
  "computer_permissions",
  {
    title: "Check permissions",
    description:
      "Check whether this host has the macOS permissions needed by the other computer_* tools: " +
      "Accessibility (mouse/keyboard/accessibility tree) and Screen Recording (screenshots, window titles). " +
      "Use this first when other tools fail, or with prompt=true to open the System Settings panes.",
    inputSchema: { prompt: z.boolean().optional().describe("Open the relevant System Settings panes if not granted") },
  },
  async ({ prompt }) => {
    const out = JSON.parse(await runCli(["perms", ...(prompt ? ["--prompt"] : [])]));
    return fmt(out);
  }
);

// ---------- screen ----------

server.registerTool(
  "computer_screenshot",
  {
    title: "Take screenshot",
    description:
      "Capture the screen and return the image so you can see it. Optionally capture a region " +
      "(x,y,w,h in global top-left-origin coordinates) or a specific display. Use this to verify " +
      "the result of clicks/typing and to plan the next action. By default the image is scaled so " +
      "1 image pixel = 1 screen point, so coordinates read off it can be passed straight to " +
      "computer_click/computer_element_at. fullRes and png are independent: fullRes=true keeps " +
      "native Retina pixels (then convert using the reported scale), png=true swaps JPEG for " +
      "lossless PNG at whatever resolution was selected.",
    inputSchema: {
      region: z.string().optional().describe("'x,y,w,h' — capture only this rect instead of the whole screen"),
      display: z.number().optional().describe("Display index (from computer_screeninfo) to capture"),
      fullRes: z.boolean().optional().describe("Keep native pixel resolution instead of scaling to screen points"),
      png: z.boolean().optional().describe("Lossless PNG instead of JPEG (crisper small text, bigger payload)"),
    },
  },
  async ({ region, display, fullRes, png }) => {
    const dir = await mkdtemp(join(tmpdir(), "ocu-shot-"));
    const wantPng = png === true;
    const path = join(dir, wantPng ? "shot.png" : "shot.jpg");
    const args = ["screenshot", "--out", path];
    if (region) args.push("--region", region);
    if (display !== undefined) args.push("--display", String(display));
    if (fullRes) args.push("--full-res");
    if (wantPng) args.push("--png");
    const meta = JSON.parse(await runCli(args)) as ShotMeta;
    const buf: Buffer = await readFile(path);
    // Remove the file AND the temp dir. Leaving the dir behind leaks one empty
    // directory per screenshot for the life of the machine.
    await unlink(path).catch(() => {});
    await rmdir(dir).catch(() => {});
    const mime = meta.format === "png" ? "image/png" : "image/jpeg";
    const scale = typeof meta.scale === "number" ? meta.scale : 1;
    const units = scale === 1
      ? "1 image pixel = 1 screen point"
      : `image is ${scale}x native, so screen_point = image_pixel / ${scale}`;
    return {
      content: [
        { type: "image" as const, data: buf.toString("base64"), mimeType: mime },
        {
          type: "text" as const,
          text: `Screenshot ${meta.width}x${meta.height}px (${meta.format}) at ${path}\n` +
            `Coordinate space: ${units}.`,
        },
      ],
    };
  }
);

server.registerTool(
  "computer_screeninfo",
  {
    title: "Screen info",
    description: "List connected displays with their bounds. Useful before taking region screenshots or multi-display testing.",
    inputSchema: {},
  },
  async () => fmt(JSON.parse(await runCli(["screeninfo"])))
);

// ---------- mouse ----------

server.registerTool(
  "computer_click",
  {
    title: "Click",
    description:
      "Move the mouse to (x,y) and click. Coordinates are global screen coordinates with the top-left origin " +
      "(same as screenshots and the accessibility tree). Get coordinates from a screenshot or computer_read_screen.",
    inputSchema: {
      x: z.number().describe("Global screen X coordinate (top-left origin)"),
      y: z.number().describe("Global screen Y coordinate (top-left origin)"),
      button: z.enum(["left", "right", "middle"]).optional().describe("Defaults to left"),
      count: z.number().optional().describe("1=single (default), 2=double, 3=triple click"),
    },
  },
  async ({ x, y, button, count }) => {
    const args = ["click", "--x", String(x), "--y", String(y)];
    if (button) args.push("--button", button);
    if (count) args.push("--count", String(count));
    return fmt(JSON.parse(await runCli(args)));
  }
);

server.registerTool(
  "computer_move",
  {
    title: "Move mouse",
    description: "Move the mouse cursor to (x,y) without clicking. Also useful for hover states.",
    inputSchema: { x: z.number(), y: z.number() },
  },
  async ({ x, y }) => fmt(JSON.parse(await runCli(["move", String(x), String(y)])))
);

server.registerTool(
  "computer_drag",
  {
    title: "Drag",
    description:
      "Press the mouse at (fromX,fromY), drag smoothly to (toX,toY) over --durationMs, and release. " +
      "Use for sliders, drag-and-drop, selections, resizing windows.",
    inputSchema: {
      fromX: z.number(),
      fromY: z.number(),
      toX: z.number(),
      toY: z.number(),
      durationMs: z.number().optional().describe("Drag duration in ms (default 400)"),
    },
  },
  async ({ fromX, fromY, toX, toY, durationMs }) => {
    const args = ["drag", String(fromX), String(fromY), String(toX), String(toY)];
    if (durationMs) args.push("--ms", String(durationMs));
    return fmt(JSON.parse(await runCli(args)));
  }
);

server.registerTool(
  "computer_scroll",
  {
    title: "Scroll",
    description:
      "Scroll at the current (or given) mouse position. Positive dy scrolls down, positive dx scrolls right, in line units.",
    inputSchema: {
      dx: z.number().optional().describe("Horizontal scroll amount (positive = right)"),
      dy: z.number().optional().describe("Vertical scroll amount (positive = down)"),
      x: z.number().optional().describe("Move mouse here first"),
      y: z.number().optional().describe("Move mouse here first"),
    },
  },
  async ({ dx, dy, x, y }) => {
    const args = ["scroll", "--dx", String(dx ?? 0), "--dy", String(dy ?? 0)];
    if (x !== undefined && y !== undefined) args.push("--x", String(x), "--y", String(y));
    return fmt(JSON.parse(await runCli(args)));
  }
);

// ---------- keyboard ----------

server.registerTool(
  "computer_type",
  {
    title: "Type text",
    description:
      "Type text into the focused element via keyboard events (supports unicode). Click the target field first " +
      "if it is not already focused. Newlines become Return presses.",
    inputSchema: { text: z.string().describe("Text to type") },
  },
  async ({ text }) => fmt(JSON.parse(await runCli(["type", "--text", text])))
);

server.registerTool(
  "computer_key",
  {
    title: "Press key",
    description:
      "Press a key or key combo, e.g. key='a' mod='cmd', key='return', key='escape', key='up', key='f5', " +
      "key='tab'. Valid keys: return enter tab space delete backspace escape forwarddelete up down left right " +
      "home end pageup pagedown f1-f15 a-z 0-9 - = [ ] ; ' , . / \\ `. Mods: cmd, shift, alt, ctrl.",
    inputSchema: {
      key: z.string(),
      mod: z.string().optional().describe("Comma-separated modifiers: cmd, shift, alt, ctrl"),
      repeat: z.number().optional().describe("Press this many times (default 1)"),
    },
  },
  async ({ key, mod, repeat }) => {
    const args = ["key", key];
    if (mod) args.push("--mod", mod);
    if (repeat) args.push("--repeat", String(repeat));
    return fmt(JSON.parse(await runCli(args)));
  }
);

// ---------- windows & accessibility ----------

server.registerTool(
  "computer_list_windows",
  {
    title: "List windows",
    description:
      "List on-screen windows with app, bounds and title. Use window bounds to pick click targets, " +
      "or windowId with the --window option semantics. Filter by app name.",
    inputSchema: { app: z.string().optional().describe("Only windows whose app name contains this") },
  },
  async ({ app }) => {
    const args = ["windows"];
    if (app) args.push("--app", app);
    return fmt(JSON.parse(await runCli(args)));
  }
);

server.registerTool(
  "computer_read_screen",
  {
    title: "Read accessibility tree",
    description:
      "Read the accessibility tree of an app (default: frontmost) as JSON: roles, titles, values, positions and sizes " +
      "of every UI element. This is how you find exact coordinates to click and text fields to type into. " +
      "Prefer this over screenshots for precise targeting; prefer screenshots for visual layout. " +
      "Check 'truncated': when true the tree was cut off by the node limit and elements are missing, " +
      "which also makes 'looksOpaque' null and inconclusive. When 'looksOpaque' is true, " +
      "'opacityReason' says why and 'hint' explains what to do instead.",
    inputSchema: {
      app: z.string().optional().describe("App name, bundle id, or pid. Defaults to the frontmost app"),
      depth: z.number().optional().describe("Max tree depth (default 14)"),
      max: z.number().optional().describe("Max nodes returned (default 600)"),
      full: z.boolean().optional().describe("Include the whole app tree (menu bar etc.) instead of just windows"),
    },
  },
  async ({ app, depth, max, full }) => {
    const args = ["ax"];
    if (app) args.push("--app", app);
    if (depth) args.push("--depth", String(depth));
    if (max) args.push("--max", String(max));
    if (full) args.push("--full");
    return fmt(JSON.parse(await runCli(args, 45_000)));
  }
);

server.registerTool(
  "computer_element_at",
  {
    title: "Accessibility element at point",
    description:
      "Return the accessibility element under (x,y): its role, title, value and frame. Great for checking " +
      "what you are about to click. Resolves the deepest element at that point rather than the OS hit-test " +
      "result, so it agrees with what a click would actually hit even in Chromium/Electron windows. " +
      "When 'osHitTestDiffers' is true the OS hit test returned something different (usually a whole-window " +
      "container), so trust 'role'/'node', which is what receives the click. " +
      "'axSettled' is true/false when the tree was checked against the window server, and null " +
      "when no check ran (or the point is not over a window).",
    inputSchema: { x: z.number(), y: z.number() },
  },
  async ({ x, y }) => fmt(JSON.parse(await runCli(["axpoint", String(x), String(y)])))
);

// ---------- apps ----------

server.registerTool(
  "computer_list_apps",
  {
    title: "List running apps",
    description: "List running GUI apps with pid, name, bundle id and which one is frontmost.",
    inputSchema: {},
  },
  async () => fmt(JSON.parse(await runCli(["apps"])))
);

server.registerTool(
  "computer_app",
  {
    title: "Launch / activate / quit app",
    description:
      "action='launch': open an app by name ('TextEdit') or bundle id ('com.apple.TextEdit'). " +
      "action='activate': bring a running app to the front, and un-minimize any window it left " +
      "minimized. action='quit': gracefully quit it. " +
      "Activate deliberately does NOT reposition windows that are only partly off-screen: that " +
      "is usually deliberate, and a window on another Space is never on-screen to begin with. " +
      "Check the 'repaired' field to see whether anything was changed.",
    inputSchema: {
      action: z.enum(["launch", "activate", "quit"]),
      name: z.string().describe("App name or bundle id"),
    },
  },
  async ({ action, name }) => fmt(JSON.parse(await runCli([action, name])))
);

server.registerTool(
  "computer_menu",
  {
    title: "Click menu item",
    description:
      "Navigate and press a menu item path via the accessibility API, e.g. app='TextEdit', path=['File','New']. " +
      "Reliable way to trigger app actions without knowing coordinates.",
    inputSchema: {
      app: z.string(),
      path: z.array(z.string()).min(1).describe("Menu path, e.g. ['File', 'Export As PDF']"),
    },
  },
  async ({ app, path }) => fmt(JSON.parse(await runCli(["menu", app, ...path])))
);

// ---------- escape hatches ----------

server.registerTool(
  "computer_applescript",
  {
    title: "Run AppleScript",
    description:
      "Run an AppleScript (osascript). Escape hatch for anything the other tools cannot do: dialogs, " +
      "System Events UI scripting, app-specific scripting. Examples: 'tell application \"Safari\" to make new document'.",
    inputSchema: { code: z.string().describe("AppleScript source code") },
  },
  async ({ code }) => {
    try {
      const out = await runOsascript(code);
      return jsonOut(out);
    } catch (err) {
      return errOut(errText(err));
    }
  }
);

server.registerTool(
  "computer_wait",
  {
    title: "Wait",
    description: "Wait for ms before continuing. Use after launching apps or clicking things that load asynchronously.",
    inputSchema: { ms: z.number().min(1).max(60_000) },
  },
  async ({ ms }) => {
    await new Promise((r) => setTimeout(r, ms));
    return jsonOut(`waited ${ms}ms`);
  }
);

// ---------- startup ----------

const transport = new StdioServerTransport();
await server.connect(transport);
process.stderr.write("[opencode-computer-use] MCP server ready\n");
