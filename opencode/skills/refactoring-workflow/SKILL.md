---
name: refactoring-workflow
description: Refactoring workflow. Use when restructuring code without changing behavior - safe refactor steps, run tests after every change, reduce duplication, improve naming.
---

# Refactoring Workflow

Use when restructuring code without changing behavior.

## Before You Start
1. Read the code you're changing AND its tests
2. Identify the goal: reduce duplication? improve naming? simplify logic?
3. Plan the steps with `sequential-thinking`

## Execution
- One logical change per step (don't mix rename + extract + reformat)
- Run tests after every step
- Never change public APIs or behavior

## What To Look For
- Duplicated logic → extract into shared function
- Long functions → split by responsibility
- Complex conditionals → simplify or use early returns
- Poor naming → rename to reveal intent
- Deep nesting → extract early returns or guard clauses
- Dead code → remove it
