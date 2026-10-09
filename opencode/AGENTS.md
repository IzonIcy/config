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

## Mac Control

Two MCPs give this machine full desktop and Maya control. Use them; do not
rebuild equivalents. Peekaboo covers the desktop, maya-mcp covers Maya.

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
for geometry and peekaboo for anything visual or interactive: peekaboo to
confirm the Maya window is real and framed correctly, the API to build, then
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
