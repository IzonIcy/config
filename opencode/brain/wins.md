# Wins

Approaches that held up under verification, with the evidence that proved it.

- (2026-10-21) Maya edit-verify-save loop: edit via a real AX control or API,
  then verify three ways and trust none alone — `scene_info`, screenshot, and
  the file on disk (hash + size + mtime). Proved an edit reached the file by
  reopening it later and finding the new node (`pCube2`).
- (2026-10-21) Named undo chunks (`undo_chunk.py` / `undo_step.py`): batch
  Maya edits in one named chunk, so a single undo reverts the whole batch with
  the batch name in `undone`. Verified end-to-end with three primitives.
- (2026-10) Skills-first agents: preferences as skills/AGENTS.md instead of
  per-request prompting. This setup runs on it; routing table in AGENTS.md
  drives which skill loads when.
