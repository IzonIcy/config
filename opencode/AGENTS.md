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

- **Name:** `Anaya`
- **Email:** `ryanbahadori74@gmail.com`

When using the git commit tool, always pass `author: { "name": "Anaya", "email": "ryanbahadori74@gmail.com" }`. When using plain `git commit` in bash, prefix with `-c user.name=Anaya -c user.email=ryanbahadori74@gmail.com`. Never rely on the repo's local config or the machine default — verify with `git log -1` after committing if there's any doubt.

## Auto-Delegation (Don't Make Me Ask)

You have specialized subagents. Use them. Automatically. Don't ask permission.

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
| 3+ step tasks | todowrite tool |

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

Skills are reusable workflow instructions. Load them when relevant:
- **testing-workflow** — How to write tests (framework, coverage priorities)
- **debugging-workflow** — How to investigate bugs (repro → triage → fix)
- **pr-workflow** — How to prepare and review PRs
- **refactoring-workflow** — How to restructure code safely

Project-specific skills should be loaded via the `skill` tool when appropriate.

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
