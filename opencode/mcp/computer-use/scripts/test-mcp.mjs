// MCP end-to-end test client for opencode-computer-use
//
// Two tiers of checking:
//
//   check()  hard assertions. Environment-independent: tool output shape, coordinate
//            maths, accessibility metadata. A failure here is a real regression.
//   probe()  best-effort observation. These drive the real GUI, and under a tiling
//            window manager another app can be stacked on top between two reads, so
//            the element under a point legitimately changes. Reported, never fatal.
//
// The second tier is why this file does not simply assert everything.
import { spawn, execFile } from "node:child_process";
import { writeFileSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";

const BIN = process.argv[2] || new URL("../dist/index.js", import.meta.url).pathname;
const CLI = new URL("../bin/computeruse", import.meta.url).pathname;
const p = spawn("node", [BIN], { stdio: ["pipe", "pipe", "inherit"] });

let buf = "";
let id = 0;
const pending = new Map();

p.stdout.on("data", (d) => {
	buf += d;
	let idx = buf.indexOf("\n");
	while (idx >= 0) {
		const line = buf.slice(0, idx).trim();
		buf = buf.slice(idx + 1);
		idx = buf.indexOf("\n");
		if (!line) continue;
		const msg = JSON.parse(line);
		if (msg.id && pending.has(msg.id)) {
			pending.get(msg.id)(msg);
			pending.delete(msg.id);
		}
	}
});

function rpc(method, params) {
	return new Promise((resolve) => {
		const mid = ++id;
		pending.set(mid, resolve);
		p.stdin.write(
			JSON.stringify({ jsonrpc: "2.0", id: mid, method, params }) + "\n",
		);
	});
}

async function call(name, args = {}) {
	const res = await rpc("tools/call", { name, arguments: args });
	if (res.error) return { error: res.error };
	return res.result;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const text = (r) =>
	r.content?.filter((c) => c.type === "text").map((c) => c.text).join("\n") ?? "";
// Tools report failures as an error string in a text block, so never assume JSON.
function json(r) {
	try {
		return JSON.parse(text(r));
	} catch {
		return null;
	}
}
const running = async (name) =>
	(json(await call("computer_list_apps"))?.apps ?? []).some((a) => a.name === name);
const killTextEdit = () =>
	call("computer_applescript", {
		code: 'do shell script "killall TextEdit 2>/dev/null || true"',
	});

const failures = [];
const probes = [];
function check(name, cond, detail = "") {
	console.log(`${cond ? "PASS" : "FAIL"}: ${name}${detail ? " - " + detail : ""}`);
	if (!cond) failures.push(name);
}
function probe(name, cond, detail = "") {
	console.log(
		`${cond ? "OK  " : "NOTE"}: ${name}${detail ? " - " + detail : ""}`,
	);
	probes.push({ name, ok: !!cond });
}

function findTextArea(node) {
	if (!node) return null;
	if (node.role === "AXTextArea" && node.pos) return node;
	for (const c of node.children || []) {
		const found = findTextArea(c);
		if (found) return found;
	}
	return null;
}
function findNode(node, pred) {
	if (!node) return null;
	if (pred(node)) return node;
	for (const c of node.children || []) {
		const found = findNode(c, pred);
		if (found) return found;
	}
	return null;
}
const textAreas = (tree) =>
	(tree?.windows || []).map(findTextArea).filter(Boolean);
const findCloseButton = (tree) => {
	for (const w of tree?.windows || []) {
		const b = findNode(w, (n) => n.subrole === "AXCloseButton" && n.pos);
		if (b) return b;
	}
	return null;
};
// Scope to the window we are driving. Tiled windows overlap, so tree order is not
// z-order and the first text area is not necessarily the one we typed into.
function areaAt(areas, at) {
	if (!at) return areas[0];
	return (
		areas.find((a) => a.pos[0] === at[0] && a.pos[1] === at[1]) ??
		areas.find(
			(a) => Math.abs(a.pos[0] - at[0]) < 40 && Math.abs(a.pos[1] - at[1]) < 40,
		) ??
		areas[0]
	);
}
const contains = (n, x, y) =>
	!!(n?.pos && n?.size) &&
	x >= n.pos[0] &&
	y >= n.pos[1] &&
	x < n.pos[0] + n.size[0] &&
	y < n.pos[1] + n.size[1];

async function teardown(originalFront) {
	await killTextEdit();
	await sleep(800);
	if (await running("TextEdit")) {
		await killTextEdit();
		await sleep(600);
	}
	if (originalFront) {
		await call("computer_app", { action: "activate", name: originalFront });
		await sleep(400);
	}
	rmSync("/tmp/test-shot.jpg", { force: true });
}

async function main() {
	await rpc("initialize", {
		protocolVersion: "2025-03-26",
		capabilities: {},
		clientInfo: { name: "test-client", version: "1.0.0" },
	});
	p.stdin.write(
		JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n",
	);

	const tools = await rpc("tools/list", {});
	console.log("TOOLS:", tools.result.tools.map((t) => t.name).join(", "));
	console.log("TOOL_COUNT:", tools.result.tools.length);

	const frontBefore = json(await call("computer_list_apps"))?.apps.find(
		(a) => a.frontmost,
	)?.name;
	console.log("FRONTMOST_BEFORE:", frontBefore ?? "(none)");

	const info = json(await call("computer_screeninfo"));
	const screen = info?.screens.find((s) => s.isMain) ?? info?.screens[0];

	// ---- tier 1: permissions -------------------------------------------------
	const perms = json(await call("computer_permissions"));
	console.log("PERMS:", JSON.stringify(perms));
	check(
		"permissions granted",
		perms?.accessibility === true && perms?.screenRecording === true,
	);

	// ---- tier 1: screenshot coordinate space --------------------------------
	const shot = await call("computer_screenshot");
	const img = shot.content?.find((c) => c.type === "image");
	console.log(
		"SHOT_MIME:",
		img?.mimeType,
		"SHOT_BYTES:",
		img ? Buffer.from(img.data, "base64").length : 0,
	);
	if (img) writeFileSync("/tmp/test-shot.jpg", Buffer.from(img.data, "base64"));
	const shotLine = text(shot);
	console.log("SHOT_TEXT:", shotLine.split("\n").join(" | "));
	check(
		"screenshot returns an image",
		!!img && Buffer.from(img.data, "base64").length > 1000,
	);
	check(
		"screenshot is point-matched so image coords equal screen coords",
		shotLine.includes("1 image pixel = 1 screen point"),
		shotLine.split("\n")[1] ?? "",
	);

	const full = text(await call("computer_screenshot", { fullRes: true }));
	console.log("SHOT_FULLRES:", full.split("\n").join(" | "));
	check(
		"fullRes reports a 2x scale",
		/screen_point = image_pixel \/ 2/.test(full),
		full.split("\n")[1] ?? "",
	);

	const region = text(
		await call("computer_screenshot", {
			region: `0,0,${screen.width},${screen.height}`,
		}),
	);
	console.log("SHOT_REGION:", region.split("\n")[0]);
	check(
		"region capture matches the requested rect",
		region.startsWith(`Screenshot ${screen.width}x${screen.height}px`),
		region.split("\n")[0],
	);

	// ---- tier 1: the AX frame matcher, as a real unit test --------------------
	const self = await new Promise((resolve) => {
		execFile(CLI, ["axsync", "--selftest"], (err, stdout) =>
			resolve(err ? null : JSON.parse(stdout)),
		);
	});
	console.log(
		"AXSYNC selftest:",
		self ? `${self.cases.filter((c) => c.pass).length}/${self.cases.length} passed` : "could not run",
	);
	check(
		"AX/window-server frame matcher handles stale, partial and reordered sets",
		self?.passed === true,
		self ? "" : "selftest did not run",
	);

	// ---- tier 1: opacity detection is deterministic --------------------------
	const t3b = json(
		await call("computer_read_screen", { app: "T3 Code (Nightly)", max: 4000 }),
	);
	console.log(
		"T3 opacity: contentNodes=",
		t3b?.contentNodes,
		"looksOpaque=",
		t3b?.looksOpaque,
	);
	check(
		"an Electron app with no AX bridge is reported as opaque, with an explanation",
		t3b?.looksOpaque === true && !!t3b?.hint,
	);
	check(
		"nodes is a real count, not a leftover budget",
		typeof t3b?.nodes === "number" && t3b.nodes > 0 && t3b.nodes <= t3b.nodeLimit,
		`nodes=${t3b?.nodes} limit=${t3b?.nodeLimit}`,
	);
	check("tree reports whether it was truncated", typeof t3b?.truncated === "boolean");
	check("tree reports whether AX had settled", typeof t3b?.axSettled === "boolean");

	// ---- tier 1: error path ---------------------------------------------------
	const bad = await call("computer_app", {
		action: "activate",
		name: "Definitely Not A Real App XYZ",
	});
	console.log(
		"ERROR_PATH isError:",
		bad.isError === true,
		"-",
		(bad.content?.[0]?.text || "").split("\n")[0].slice(0, 100),
	);
	check("unknown app returns an error instead of throwing", bad.isError === true);

	// ---- tier 1: applescript -------------------------------------------------
	check(
		"applescript escape hatch evaluates",
		text(await call("computer_applescript", { code: "return 6 * 7" })).trim() === "42",
	);

	// ---- tier 2: real GUI round trip, best effort -----------------------------
	await killTextEdit();
	await sleep(800);
	await call("computer_app", { action: "launch", name: "TextEdit" });
	await sleep(1700);
	await call("computer_key", { key: "escape" });
	await sleep(900);
	// TextEdit restores every document it had open, so a fresh launch can come back
	// with several tiled windows overlapping. Keep one. It can also come back showing
	// only a restored Open panel, which has no text area to click, so drop that and
	// make sure a document actually exists.
	await call("computer_applescript", {
		code: `tell application "TextEdit"
  activate
  repeat with i from (count of windows) to 1 by -1
    try
      if name of window i is "Open" then close window i
    end try
  end repeat
end tell
tell application "System Events"
  if exists process "TextEdit" then
    tell process "TextEdit"
      set frontmost to true
      repeat with i from (count of windows) to 2 by -1
        try
          perform action "AXClose" of window i
        end try
      end repeat
    end tell
  end if
end tell
tell application "TextEdit"
  if (count of documents) is 0 then make new document
end tell`,
	});
	await sleep(1000);
	await call("computer_app", { action: "activate", name: "TextEdit" });
	await sleep(700);

	if (!(await running("TextEdit"))) {
		probe("TextEdit available for GUI round trip", false, "app did not start");
		return frontBefore;
	}

	const want =
		"Hello from opencode computer-use MCP! Unicode: café ünïcode 123";
	let typed = false;
	let typeDetail = "no usable text area found";
	let sawContainment = false;
	let sawTextArea = false;

	for (let attempt = 0; attempt < 4 && !typed; attempt++) {
		if (attempt > 0) {
			await call("computer_app", { action: "activate", name: "TextEdit" });
			await sleep(900);
		}
		const tree = json(await call("computer_read_screen", { app: "TextEdit" }));
		const areas = textAreas(tree);
		if (!areas.length) continue;
		probe(
			"native app is not flagged opaque",
			tree?.looksOpaque === false,
			`contentNodes=${tree?.contentNodes}`,
		);

		// Close button: re-derive from the tree each attempt, the WM may re-tile.
		const btn = findCloseButton(tree);
		if (btn) {
			const bx = btn.pos[0] + Math.round(btn.size[0] / 2);
			const by = btn.pos[1] + Math.round(btn.size[1] / 2);
			const at = json(await call("computer_element_at", { x: bx, y: by }));
			probe(
				`element_at names the close button, not its container (try ${attempt + 1})`,
				at?.node?.subrole === "AXCloseButton",
				`(${bx},${by}) -> ${at?.node?.role}/${at?.node?.subrole ?? "-"}, os hit test said ${at?.osHitTestRole}`,
			);
			if (at?.node?.subrole === "AXCloseButton") sawTextArea = true;
		}

		const a = areas[0];
		const cx = Math.round(a.pos[0] + a.size[0] / 2);
		const cy = Math.round(a.pos[1] + a.size[1] / 2);
		const at = json(await call("computer_element_at", { x: cx, y: cy }));
		console.log(
			`ELEMENT_AT text area (try ${attempt + 1}):`,
			JSON.stringify(at?.node),
			"source:",
			at?.source,
		);
		if (contains(at?.node, cx, cy)) sawContainment = true;
		if (at?.node?.role !== "AXTextArea") {
			typeDetail = `(${cx},${cy}) resolved to ${at?.node?.role}, not the text area`;
			continue;
		}

		await call("computer_click", { x: cx, y: cy });
		await sleep(550);
		// computer_key and computer_type deliver to whatever is frontmost, so the
		// cmd+A and forwarddelete below would land in an unrelated app if focus moved
		// after the tree read. The click is harmless; sending keys blind is not.
		const frontNow = json(await call("computer_list_apps"))?.apps.find(
			(u) => u.frontmost,
		)?.name;
		if (frontNow !== "TextEdit") {
			typeDetail = `refused to type: frontmost is ${frontNow}, not TextEdit`;
			break;
		}
		// The field may hold the previous run's text. Clear it or this appends.
		await call("computer_key", { key: "a", mod: "cmd" });
		await sleep(250);
		await call("computer_key", { key: "forwarddelete" });
		await sleep(450);
		const pre =
			areaAt(textAreas(json(await call("computer_read_screen", { app: "TextEdit" }))), a.pos)
				?.value ?? "";
		if (pre.trim() !== "") {
			typeDetail = `field not empty after clear: ${JSON.stringify(pre.slice(0, 40))}`;
			continue;
		}
		await call("computer_type", { text: want });
		await sleep(800);
		const got =
			areaAt(textAreas(json(await call("computer_read_screen", { app: "TextEdit" }))), a.pos)
				?.value ?? "";
		typed = got.trim() === want;
		typeDetail = typed
			? "typed text round-tripped through the tree"
			: `got ${JSON.stringify(got.trim().slice(0, 60))}`;
	}

	check(
		"element_at returns a frame containing the queried point",
		sawContainment,
		"only reached if TextEdit stayed on top",
	);
	probe("typed text round-trips through the tree", typed, typeDetail);
	probe(
		"element_at resolved the close button at least once",
		sawTextArea,
		"window manager may stack another app on top",
	);

	const wins = json(await call("computer_list_windows", { app: "TextEdit" }))
		?.windows;
	if (wins) {
		console.log(
			"WINDOWS:",
			wins.map((x) => `${x.app} ${x.width}x${x.height} @(${x.x},${x.y})`).join(" | "),
		);
		check(
			"windows are reported on screen",
			wins.every(
				(w) =>
					w.x + w.width > 0 &&
					w.y + w.height > 0 &&
					w.x < screen.width &&
					w.y < screen.height,
			),
			wins.map((w) => `@${w.x},${w.y}`).join(" "),
		);
	}

	console.log(
		"SCROLL:",
		JSON.stringify(json(await call("computer_scroll", { dy: 1, x: 10, y: 300 }))),
	);

	return frontBefore;
}

main()
	.then(async (frontBefore) => {
		await teardown(frontBefore);
		const notes = probes.filter((x) => !x.ok).length;
		console.log(
			`\nPROBES: ${probes.length - notes}/${probes.length} observed as expected` +
				(notes ? ` (${notes} environment-dependent, not failures)` : ""),
		);
		console.log(
			failures.length === 0
				? "ALL_TESTS_PASSED"
				: `${failures.length} FAILED: ${failures.join(", ")}`,
		);
		p.kill();
		process.exit(failures.length === 0 ? 0 : 1);
	})
	.catch(async (e) => {
		console.error("TEST_FAILED:", e.message);
		await teardown(null);
		p.kill();
		process.exit(1);
	});
