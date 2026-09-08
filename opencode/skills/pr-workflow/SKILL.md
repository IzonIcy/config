---
name: pr-workflow
description: Pull request workflow. Use when preparing, opening, or reviewing a pull request - rebase onto main, run tests/typecheck/lint, PR title and body structure, review checklist.
---

# Pull Request Workflow

Use this when preparing or reviewing a pull request.

## Before Opening
1. Rebase onto latest main: `git pull --rebase origin main`
2. Run full test suite: `pnpm test`
3. Run type check: `tsc --noEmit` or equivalent
4. Run lint: `pnpm lint`

## PR Structure
- Title: `type(scope): concise description`
- Body: What problem + How you fixed it
- UI changes = include before/after screenshots
- One concern per PR

## Review Checklist
- [ ] No dead code or unused imports
- [ ] Error paths are handled
- [ ] Tests added/updated
- [ ] No breaking API changes (unless intentional)
- [ ] Documentation updated if needed
