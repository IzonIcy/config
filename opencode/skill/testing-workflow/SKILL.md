---
name: testing-workflow
description: Testing workflow. Use when adding or fixing tests for any project - discover existing test config and patterns first, cover happy path/edge cases/error paths/regressions, keep tests deterministic.
---

# Testing Workflow

Use this when adding or fixing tests for any project.

## Discovery
1. Read the project's test config (`vitest.config.ts`, `jest.config.js`, `pytest.ini`, etc.)
2. Read 2-3 existing test files to match the pattern
3. Check if there's a `AGENTS.md` or project instructions for test conventions

## Coverage Requirements
Write tests for (in priority order):
- Happy path (normal expected usage)
- Edge cases (null/undefined, empty arrays, boundary values)
- Error paths (what happens on failure?)
- Regressions (check git log for past bugs in this area)

## Rules
- Each test tests ONE behavior
- Test names = sentences: `'returns 404 when user is not found'`
- No shared mutable state between tests
- No reliance on external services (mock at boundaries)
- Run tests after every change
