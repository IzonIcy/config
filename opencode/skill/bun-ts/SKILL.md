---
name: bun-ts
description: Bun + TypeScript conventions. Use when working on Bun projects - bun as runtime/package manager/test runner instead of npm or node, Bun.serve(), Biome linting, bunx over npx.
---

# Bun + TypeScript Conventions

## Runtime
- **Bun** is the runtime, package manager, and test runner
- Do NOT use `npm` or `node` — use `bun` for everything
- Bun supports TypeScript natively — no need for `tsc` compilation

## Tooling
- `bun run src/index.ts` to run scripts
- `bun test` for testing
- `bunx` instead of `npx` (e.g., `bunx biome check src`)
- `bun --watch` for auto-reload during development
- Use `bun build` for compiling binaries
- Use **Biome** for linting and formatting (not ESLint or Prettier)

## Script Commands
- `bun run <script>` to run package.json scripts
- `bun add <pkg>` to add dependencies
- `bun remove <pkg>` to remove dependencies

## Project Structure
```
src/
├── index.ts        # Entry point
├── commands/       # CLI command handlers
├── services/       # Business logic
├── clients/        # External API clients (Discord, Slack, etc.)
├── types/          # Type definitions
└── utils/          # Helpers
```

## Conventions
- Use `type: "module"` in package.json
- Use `Bun.file()`, `Bun.write()`, `Bun.env` for file/env operations
- Use `Bun.serve()` for HTTP servers (not Express)
- TypeScript with strict mode enabled
- Prefer `const` and `function` over `class` where possible
- Use `zod` for runtime validation against external APIs
