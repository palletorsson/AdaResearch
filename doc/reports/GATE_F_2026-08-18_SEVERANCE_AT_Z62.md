# Gate F, 2026-08-18: the walk is severed at z=62, and the two best explanations are both wrong

**Morning breath, 09:08–09:35. Written while another session held the museum.** This is a
handoff note, not a repair. The breath did not touch a museum file, for reasons in the last
section.

## The reading

Release gate F (three-museum autopilot walkthrough), run at HEAD `f490260a5`:

```json
{"ok": false, "reason": "no_route", "z_reached": 62.0, "goal_z": 107.0,
 "museums": 3, "segments_built": 3, "walked_s": 51.5,
 "cells_unlearned": 15, "stall_events": 23, "frontier_z": 61,
 "seal_overflow": 9, "x": 11.4999, "z": 61.985}
```

The walk **completed** — `done: true`, 51.5 s, three segments built. This is not a
lock-death, even though two other Godot processes were live at the time. The walker built
its museums, walked to z=62 of a 107 goal, and stopped.

Trust the instrument here. Before 2026-08-15 this gate reported `unlearn_budget` with a
fabricated cell count, because `_auto_path` was never cleared on the planner's early
returns and the walker ground against a corpse plan
(`doc/reports/GATE_F_PLANNER_DIAGNOSIS.md`). That was fixed. `no_route` with a real cut
list is the repaired instrument's honest verdict shape.

## Where it stops

`ada_run/em_autopilot.json` dumps the frontier's far side. Eight cells, and they close a
row:

| x | z | erased by |
|---|---|---|
| 5 | 61 | `seal:game_of_life_petri` |
| 6, 7, 8, 9, 11 | 62 | `stall` |
| 10, 12 | 61–62 | `never` |

One honest seal, five stalls, two never-attempted. **The z=62 row is closed across x=5..12
and the walker is pinned at (11.50, 61.99).** A `stall` means physics disagreed with the
cell map: the plan routed into a cell a collider owns.

Last known green: **2026-08-16 evening**, `z_reached 102.0 / goal 102.0`, `cells_unlearned
0`, `stall_events 0`. So the regression window is roughly 39 hours — all of 08-17's trunk /
branches / side-room / hero-walk work and 08-18's pearls. Note `goal_z` moved 102 → 107 and
`ada_run/em_plan.json` was rewritten by `ac78d0ef2`: **this walk is over a different plan**,
so this is not a like-for-like comparison with the green run.

## Two explanations that look right and are not

Both were pursued to the source and both died there. Recording them so the next reader does
not spend the same hour.

**1. The nine mesh seal overflows.** `seal_overflow: 9` with a named near-case —
`curation_station` at cell (11,64), raw AABB `[10,14,63,67]`, sealed `[10,13,63,66]`. Two
cells of body left standing in walkable map, two cells from the frontier. The comment at
`endless_museum.gd:3783` even names the failure in advance: *"an UNDER-seal being
manufactured... the plan sends it into a cell the collider owns, physics refuses, and the
stall handler unlearns the cell one at a time."*

It does not hold. That comment predates the block directly under it. `_occupied_cells`
clamps **meshes** to `MAX_SEAL_RADIUS = 2`, then seals **collision extent separately and
unclamped** out to `MAX_BODY_RADIUS = 6` (line 3828). A walker is stopped by colliders, not
meshes. A mesh-only overflow is cosmetic. `seal_overflow` is a *mesh* record, and reading it
as the cause of a stall is reading the wrong instrument — the exact trap this file's own
history keeps setting.

Still worth one check by whoever owns this: **is any collider in this plan wider than 13
cells** (the `MAX_BODY_RADIUS = 6` span)? That one *would* clamp, and that one *would*
stall. The overflow list does not currently record collider clamps — only mesh clamps. If it
recorded both, this question would already be answered.

**2. This morning's tree-await guard.** `d32a9199b` and `198056576` put
`if not is_inside_tree(): await tree_entered` into 20 files, including
`curation_station.gd` — the token in `seal_overflow_near`. A deferred build measures small
at seal time, and the seal is taken at a fixed instant (the code acknowledges this at line
3731). Tempting, and the coincidence of file and token is real.

It does not hold either, and the commit message says why: *"In-tree callers are untouched —
the branch is false and the same frame is awaited, so today's timing is byte-identical."*
Museum artifacts are added to the tree. The branch never fires for them.

## What is actually left

The structural change in the window, not yet excluded: **`1dc6a2a9f`, "ONE SEGMENT PER
PEARL"** — segment boundaries are now derived per-pearl rather than per-chapter. Seams came
back `[[0,34],[34,74],[74,107]]`, and the frontier at z=61 sits in the *middle* of segment 2,
not at a seam. That argues against a seam-stitching bug and for something dealt into that
segment. Which is where the next person should look, with the cut list in hand.

Cheapest next test, and it needs no Godot: `tools/test_autopilot_planner.py` already
transcribes the planner into Python. Feeding it the z=62 row from this cut list says whether
the planner *should* have routed around it — separating "the plan is impossible" from "the
planner gave up".

## Why this breath did not fix it

The museum was under live development throughout. Three Godot processes (one started at
09:08:27, mid-measurement), HEAD advancing `f490260a5 → b9668aa60 → 590c84eb6` during the
run, `ada_run/gates.json` rewritten at 09:07, 892 dirty files concentrated in exactly
`commons/scenes/endless_museum.gd`, `commons/scenes/em/*`, `commons/testing/test_em_*`.

That session's own gate sweep (head `ac78d0ef2`) is 13 green and one red — `side_room`,
"FAIL 1". **It has no autopilot row.** They are not running the walk, so as far as I can
tell this Gate F failure is not yet known to the person causing or fixing it. That is the
reason this note exists.

Editing `endless_museum.gd` into that would have raced their commits and made both
measurements unreadable. The finding is worth more than the collision.
