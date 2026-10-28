# pstack model configuration

Per-role model overrides for pstack skills. Each pstack SKILL.md names its defaults in a Models section; the values here override those defaults. Delete a line to fall back to the skill default. A value of `inherit-parent` or `auto` runs that role on the parent session's model (the dispatch omits `model`); an alias entry in a panel list still counts toward that panel's fan-out. A model may carry a reasoning effort, as in `opencode/beam-free @xhigh`; the role's subagent then runs at that level. `default effort` sets the level for a value without one; `session` keeps the parent session's effort. `session hook` is inert on OpenCode, kept for portability.

feature, refactoring: opencode/glm-5.3-flash-free
bug-fix: opencode/beam-free
perf-issue: opencode/beam-free
hillclimb: opencode/beam-free
judgment and prose: opencode/glm-5.3-flash-free
strongest judgment: opencode/deepseek-v4.1-flash-free @max
how explorer: opencode/flint-40b-free
how explainer: opencode/glm-5.3-flash-free
why investigators: opencode/glm-5.3-flash-free
why synthesizer: opencode/beam-free
reflect tooling: opencode/flint-40b-free
reflect judgment, divergent, synthesizer: opencode/beam-free
arena runners: opencode/glm-5.3-flash-free, opencode/beam-free, opencode/flint-40b-free, opencode/deepseek-v4.1-flash-free
arena cross-judge pool: opencode/glm-5.3-flash-free, opencode/beam-free, opencode/flint-40b-free
swarm workers: opencode/glm-5.3-flash-free
architect runners: opencode/glm-5.3-flash-free, opencode/beam-free, opencode/flint-40b-free, opencode/deepseek-v4.1-flash-free
interrogate reviewers: opencode/beam-free, opencode/deepseek-v4.1-flash-free, opencode/glm-5.3-flash-free, opencode/flint-40b-free

default effort: session
session hook: off
