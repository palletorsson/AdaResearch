# Gate F: the number was about the planner, not the museum

**2026-08-15, morning breath.** Release gate F — the endless museum's three-museum
walkthrough — has been red and immobile since at least 2026-08-13, with a verdict that
repeated to ten decimal places across runs:

```json
{"ok": false, "z": 44.6501121520996, "x": 7.49987840652466,
 "goal_z": 102.0, "segments_built": 3, "cells_unlearned": 26}
```

Three previous breaths read that as a corridor needing more than 25 cells unlearned — a
museum too broken to walk — and each of them was blocked from investigating by a live
Godot session holding the `user://` lock. The reading was wrong.

## What `cells_unlearned` was counting

Not cells. Stall events.

The autopilot's design is sound: walk the BFS plan, and where physics disagrees with the
stamped cell map, erase the offending cell and route around it. A budget of 25 keeps it
honest — a corridor that needs endless unlearning is a broken corridor.

The implementation leaks. In `commons/scenes/endless_museum.gd`, `_auto_path` is assigned
in exactly one place (the success tail of `_auto_plan`) and cleared nowhere. Both of the
planner's early returns —

```gdscript
if not found:
    return          # no stamped cell within r=3 of the walker
...
if best == start:
    return          # BFS found nothing deeper than where we stand
```

— leave the previous plan standing. So when BFS runs out of route, the walker keeps
following a corpse whose head is the very cell the stall handler just erased. It grinds
into the wall, stalls after 1.2 s, and erases that cell again. `Dictionary.erase` on a
missing key is a silent no-op, so nothing changes, but `_auto_learned` increments anyway.
The budget meant for honest repair is spent on refusing the same lesson.

That is why the position repeated to ten decimals. The walker was not searching. It was
pinned.

## The proof, without Godot

`tools/test_autopilot_planner.py` transcribes `_run_autopilot` / `_auto_plan` into Python
and puts them in front of a wall they cannot pass. Five assertions, all passing:

| case | verdict | reported | real cells | stalls |
|---|---|---|---|---|
| HEAD, 8-wide sealed row | `unlearn_budget` | 26 | 8 | 26 |
| fixed, same corridor | `no_route` | 8 | 8 | 16 |
| fixed, 40-wide sealed row | `unlearn_budget` | 26 | 26 | 26 |
| both, clear corridor | pass | 0 | 0 | 0 |

Be precise about what this shows. The bench reproduces the **control flow**, not the
museum's geometry: 26 is forced by the budget and 8 is the wall width I chose, so the
match with the live figure is a fit, not a prediction. What is not by construction is the
shape — eighteen of twenty-six stall events erasing nothing, and the walker frozen at one
coordinate throughout. The third row is the one that makes the fix safe to land: a wall
genuinely wider than the budget still fails, so this cannot turn red into green.

## The fix

- `_auto_plan` clears the path at both early returns. Deciding nothing now says nothing.
- The budget counts cells that actually left the map. `erased = _walk_cells.erase(...)`.
- Eight consecutive stalls that erase nothing terminate the run as `reason=no_route` —
  its own verdict, distinct from an exhausted repair budget.
- The verdict file gained `stall_events`, `frontier_z`, `reason`, and `seams`.

`seams` is there because the scene's stdout is not capturable from the non-console exe, so
the segment table has to travel in the file. Where the frontier falls means nothing until
you can read it against the joins.

## What the gate says now

```
FAIL — 3 museums, z=44.6/102.0, 33.2s walked, 6 cells unlearned,
       14 stall events, frontier z=44, reason=no_route
seams: [[0,34],[34,68],[68,102]]
```

Still red, and it should be: the museum genuinely cannot be walked past z≈45. But the
failure is now legible, and three things are settled that were not before.

1. **Six cells, not twenty-six.** Eight of the fourteen stalls were the grinder.
2. **The walk map is severed, not expensive.** After six repairs nothing deeper is
   reachable at all. This is a hole, not a thicket.
3. **It is not a joining fault.** z=44 sits 10 m inside segment 2, whose seam is at 34.
   The walker crossed the first join without trouble. The obstruction is inside the second
   museum, near x=7.

It also fails 30% faster — 33.2 s against 47.6 s — because it stops as soon as it has
nothing left to learn.

## The next question, now well posed

What sits at z≈45, x≈7 in the second segment, and why does removing six cells not open it?

One candidate is worth checking first. The bench-placement code guards its erasures
explicitly — *"never plug a passage: both neighbours along the wall must be floor, and so
must the cell the walker will squeeze past on"*. The prop dealer's erasure, which
surrenders a walk cell for any prop with `occupies_floor`, carries no such guard. A floor
prop dealt into a doorway would sever the map exactly like this, and the six unlearned
cells would be the walker trying every way around a door that no longer exists.

That is a hypothesis, not a finding. It needs a dump of `_walk_cells` around z 40–50.

## The standing lesson

This is the fourth time in recent memory that a confident verdict turned out to be a fact
about the rig. The tell each time is the same: a number that is too stable. A walk through
a procedurally dealt museum should not land on the same coordinate to ten decimal places
twice. Determinism explained the repetition, but it should have prompted the question of
what, exactly, was being repeated.

Count the thing being measured before believing any null.
