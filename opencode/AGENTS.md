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
