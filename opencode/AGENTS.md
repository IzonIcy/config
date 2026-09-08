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

| Task | Who |
|------|-----|
| Code review / audit | @review |
| Writing tests | @test |
| Bug fixes / debugging | @debug |
| Refactoring / restructuring | @refactor |
| Explaining code | @explain |
| Writing documentation | @docs |
| Writing commit messages | @commit |
| Auto-fixing lint/style | @fix |
| Architecture planning | @plan |

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

| Situation | Skill |
|-----------|-------|
| User asks for a non-trivial feature, refactor, or design change | **grill-with-docs** — interview BEFORE writing code; build the project's CONTEXT.md vocabulary as you go |
| User floats an underbaked plan, idea, or decision (non-code) | **grill-me** |
| Alignment reached on spec-worthy work | **to-spec** to publish it, then offer **to-tickets** |
| Executing a spec or tickets | **implement** — drives tdd + code-review at pre-agreed seams |
| Building anything with testable behavior | **tdd** — red-green-refactor, failing test FIRST |
| Bug resists the obvious fix, or repro is unclear | **diagnosing-bugs** — feedback loop → minimise → hypothesise → fix → regression-test |
| Meaningful changes done, about to commit | **code-review** before committing |
| User says "wait what", "huh?", or clearly didn't follow | **wait-what** — re-pitch with the missing context, plain English |
| Long session wrapping up with work remaining | **handoff** — compact into a handoff doc for the next agent |
| User mentions shoehorn / `as` assertions in tests | **migrate-to-shoehorn** |
| User wants pre-commit hooks / Husky / lint-staged | **setup-pre-commit** |
| User wants exercise scaffolds (sections/problems/solutions) | **scaffold-exercises** |

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

## Review Checklist

- Dead code, unused imports, missing error handling
- Security: XSS, injection, secrets exposure
- Public API clarity — can someone figure out how to use this without reading the implementation?
- Every PR should be understandable in under 2 minutes
