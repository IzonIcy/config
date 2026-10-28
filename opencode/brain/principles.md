# Principles

Lessons that have held in more than one session. Each links its sources;
promote only after a repeat, demote when contradicted.

- **Trust scene/file/DB state over pixels.** When an image capture and the
  queryable data disagree, the data wins for existence, the pixels for
  appearance, and the disagreement gets investigated.
  Sources: wins.md (Maya edit loop), quirks.md (stale captures).
- **One unresolved claim is worse than one honest "couldn't verify".** Verify
  with independent channels; if impossible, say so and point at what would
  prove it. Sources: verification skill, the fake-negative `type` retry trap.
- **Vacate the machine in the same session you occupied it.** Copies removed,
  ports released, baseline hashes re-checked. Sources: wins.md (Maya file
  round trip).
- **Reversibility first on anything a user cares about.** Copy before
  mutate, named undo chunks, confirm before overwrite. Sources: AGENTS.md
  Maya section, corrections.md.
