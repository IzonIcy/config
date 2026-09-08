---
name: debugging-workflow
description: Debugging workflow. Use when investigating a bug, failure, error, crash, or failing test - reproduce, triage, isolate, fix, verify, and add a regression test.
---

# Debugging Workflow

Use this when investigating a bug or failure.

## Step 1: Reproduce
- What's the exact error message?
- What input triggers it? What state is required?
- Can you reproduce it consistently?

## Step 2: Triage
Check these in order:
1. Type errors — `tsc --noEmit` or your type checker
2. Lint errors — `pnpm lint`
3. Runtime errors — check the stack trace
4. Logic errors — trace through the code path
5. Race conditions — are there concurrent operations?
6. Data issues — is the data shape what you expect?

## Step 3: Isolate
- Strip away unrelated code
- Create the minimal reproduction
- Use `sequential-thinking` to enumerate causes

## Step 4: Fix & Verify
- Fix the root cause, not the symptom
- Add a regression test
- Verify the original failure case is resolved
