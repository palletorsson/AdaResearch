# Gate F, 2026-08-19: the museum's exit door opens onto the bridge court's end rail

**Morning breath, 09:04–09:40.** Unlike the last five gate F notes, this one names a
mechanism rather than a coordinate, it is proved from the builder's own output rather than
inferred from the walker's, and the whole 86-row failure reduces to **three cells**.

## The reading

Release gate F, run at HEAD `95ae0c3bd`:

```json
{"ok": false, "reason": "no_route", "z_reached": 28.2, "goal_z": -1.0,
 "museums_target": 3, "segments_built": 2, "elapsed_s": 17.2,
 "cells_unlearned": 0, "stall_events": 8, "frontier_z": 28, "seal_overflow": 0,
 "seams": [[0, 64], [64, 115]]}
```

Two things about this verdict before anything else.

**`goal_z: -1.0` is not a bug, it is the shape of an early death.** `_auto_goal_z` is only
assigned when the *N*th museum finishes building (`endless_museum.gd:2542`). The walker died
inside museum 1, so museum 3 never built, so the goal was never set. The gate printed
`z_reached 28.2 / goal_z -1.0` and called it FAIL, which is right, but `28.2 of -1.0` is not
a fraction and should not be read as one. Against the seams the walk actually died **28 m
into a 115 m route**.

**`cells_unlearned: 0` with `seal_overflow: 0` is the tell.** Every previous gate F failure
in this corpus blamed a seal — a body sealed too small, or too large. This one has no seals
in the cut and unlearned nothing. All twelve cut cells read `never`: **the builder never
stamped them.** That is not an obstruction, it is a hole.

## The mechanism

`ada_run/em_built.json` records the role of every cell the builder stamped. Reading it
directly (`tools/check_walk_severance.py`, new in this breath) reproduces the walker's
answer in under a second with no Godot:

```
flood: from (1, 1) reaches z=28 of 114  (86 rows short)
cuts: 1

  z=28 -> z=29   [inside one museum]
    0:sainsbury-false-perspective-enfilade
    open at z=28    x = [6, 7, 8]
    open at z=29    x = [1, 2, 3]
    the two rows share no column: nothing can step across
    z=26   ##...#.........#############
    z=27   ##...#.........#############
    z=28   #######...################## <<
    z=29   ##...####################### <<
    z=30   ##...#......................
    z=31   ##...#......................
```

`z=28` is the museum tile's **last row** — its back wall, whose only opening is the enfilade
door at `x=6,7,8`. `z=29` is the **first row of the courtyard**, and its only floor is the
bridge at `x=1,2,3`.

The two are disjoint. The door does not lead to the bridge, and the bridge cannot be
entered from the door.

`BRIDGE_COURT_PATH_W = 4`, and the bridge branch stamps `for x in range(1,
BRIDGE_COURT_PATH_W)` — **x=1,2,3, always, regardless of where the tile puts its door.** The
sainsbury tile centres its enfilade, so its exit is at x=6,7,8. Nothing joins them.

This is not merely a map fault that stamping three cells would fix honestly. The court's
end rail is built at `edge_z = zcur - 0.125` spanning the full court width (`x` 4..29, 1.1 m
high, with a collider). A walker stepping out of the door at x=6,7,8 meets that rail. **The
cell map is telling the truth; the build is sealed.**

## Why it fires here and not in segment 2

Segment 2 (z 64..115, the same museum tile) crosses its own back wall fine:

```
 92 #######...##################     <- exit door, x=6,7,8
 93 ##.............#############     <- full width
```

Two differences, and both come from the plan, not the code:

| | segment 0 | segment 1 |
|---|---|---|
| forecourt rows dealt | 0 (`porch_depth` 0) | 7 (`porch_depth` 3) |
| first court `access` | **`bridge`** | `""` (centred) |

A centred court stamps the full width at its first row. A bridge court stamps three columns
at a fixed x. So the fault is conditional on the *data*: **a bridge court dealt first, with
no forecourt to separate it from the tile, severs the museum.** That is why gate F was green
at 102.0/102.0 on 08-16 and is red today — the code did not regress, this morning's spine
run (`_spine_run.at 2026-08-19T07:54:31`, 219 plans) dealt a pearl that hits the condition.

There is no guard for the abutting case. `_build_courtyard` sets `z0 = VESTIBULE_H + tile_h`
and starts `zcur` there; the bridge branch never asks whether `zcur == z0`, i.e. whether it
is the court that meets the tile's back wall.

## The three cells, measured

Patch row 29 of segment 0 to open `x=6,7,8` and re-read:

```
flood: from (1, 1) reaches z=114 of 114  (WHOLE)
cuts: none
```

**One three-cell join is the entire failure.** Nothing else in 115 m of museum is cut. That
is worth stating plainly because it bounds the repair: this is not a corridor that needs
rethinking, it is a door that opens into a rail.

## What the repair has to do (not done in this breath)

Not attempted here — `commons/scenes/endless_museum.gd` was being worked by a concurrent
session (two live Godot processes, `em_plan.json` rewritten 08:57, scene touched 08:43). The
file is clean against HEAD, so this verdict is about HEAD and the repair is safe to make; it
was the *collision* that was unsafe, not the diagnosis.

Three candidate repairs, in order of how little they invent:

1. **Open the end rail under the door.** When `zcur == z0` (the court abuts the tile), split
   the `edge_z = zcur - 0.125` rail around the tile's exit door span and stamp those cells.
   The rail exists to stop the planner routing across the court's z-ends into the next
   vestibule (comment at `endless_museum.gd:3434`); an opening at the door is exactly the
   place it should not be stopping anyone.
2. **Put the bridge under the door.** Offset the bridge's x range to the tile's exit span
   rather than pinning it at 1..3. Larger blast radius: the bridge x is assumed in the deck
   boxes, the divider rail, and the apron test.
3. **Never deal a bridge court first.** A plan-side ordering rule. Cheapest, and it leaves
   the fault standing for whoever next changes the plan generator.

(1) is the honest one: it fixes the build rather than avoiding the case.

## What this changes about how gate F gets read

Five consecutive breaths asked gate F where the museum was severed and got back
`frontier_z` — a coordinate with no mechanism — then spent the session guessing the
mechanism from the coordinate. Four of those guesses were wrong, and each cost a breath.

The builder was writing the answer the whole time. `em_built.json` carries every stamped
cell's role, the museum is a corridor along +z, and therefore **any adjacent pair of z rows
that share no walkable column is a proof of severance** — no walk required, no Godot, no
`user://` lock, no 50-second wait, and it works on a contended tree. That is
`tools/check_walk_severance.py`. It reports the cut (the mechanism) and a flood (the
verdict), and its exit code is the cut count, so it can gate.

The general lesson is the corpus's own, one more time: the fix was never a better inference
from the same fields. It was reading a file that already had the answer in it.
