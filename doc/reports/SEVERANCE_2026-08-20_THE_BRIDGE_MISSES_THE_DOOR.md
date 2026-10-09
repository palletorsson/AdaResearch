# The bridge misses the door — four museums, one line

**2026-08-20 morning breath. Measured at HEAD `0010a10c8`, on a working tree with a
live concurrent writer in it. Not repaired here — see "Why this is a handoff".**

## The verdict

```
WALK SEVERANCE: FAIL — flood reaches z=1360 of 2435 (1075 rows short), 4 cut(s);
first at z=1360->1361 in 24:altes-rotunda-hub (inside one museum),
open [6, 7, 8] vs [1, 2, 3]
```

A body spawning at the mouth of the endless museum can reach z=1360 of 2435. The
remaining 1075 rows — sixteen of the forty museums dealt this morning — are behind
a wall it cannot step through. `python tools/check_walk_severance.py`, 0.2 s, no
Godot, no `user://` lock.

## The mechanism, and it is the same one four times

Every cut has one shape. The row above opens only at the museum tile's back door;
the row below opens only at x=1,2,3.

```
z=1358 ##.............#############
z=1359 ##.............#############
z=1360 #######...################## <<  the tile's back door, x = 6,7,8
z=1361 ##...####################### <<  the bridge,          x = 1,2,3
z=1362 ##...#..................####     bridge + court beside it
```

| cut | segment | museum | door x | bridge x |
|-----|---------|--------|--------|----------|
| z=1360 → 1361 | 24 | altes-rotunda-hub | 6,7,8 | 1,2,3 |
| z=1690 → 1691 | 29 | altes-rotunda-hub | 6,7,8 | 1,2,3 |
| z=1822 → 1823 | 31 | castelvecchio-endstopped-enfilade | 4..13 | 1,2,3 |
| z=2017 → 2018 | 34 | castelvecchio-endstopped-enfilade | 11,12,13 | 1,2,3 |

The bridge is stamped at a fixed x, at `commons/scenes/endless_museum.gd:3998`:

```gdscript
for x in range(1, BRIDGE_COURT_PATH_W):      # BRIDGE_COURT_PATH_W == 4  ->  x = 1,2,3
    _walk_cells[Vector2i(x, zbase + zz)] = true
```

`x` here is not derived from anything. It does not ask where the tile put its
door. And the first court always meets that door, because `_build_courtyard`
starts at `z0 = VESTIBULE_H + tile_h` (line 3954) — the row immediately after the
tile. So whenever a museum is dealt a **bridge court first**, with no forecourt
rows between it and the tile, the museum severs. Four of forty were dealt that way
this morning; the third row of the table shows a door ten cells wide missing a
three-cell bridge, which is how little the two have to do with each other.

This is not a regression. `_build_courtyard` has never asked the question. It is
conditional on the deal, which is why gate F was 102.0/102.0 green on 08-16 and is
red now, and why it will go green again on its own the next time the spine deals
differently. That property is what makes it a gate's job and not a memory's.

## This was already diagnosed once, and the count went 1 → 4

The 08-19 breath found this exact mechanism at z=28 of that morning's build, named
it, measured the repair (patching three cells open took the flood from z=28 to
z=114, WHOLE, cuts 1 → 0), and built `tools/check_walk_severance.py` to prove it.

It then left the detector unplugged. Between 08-19 and this morning, the only
mention of `check_walk_severance` anywhere in the repository — every `.py`,
`.json`, `.md`, `.ps1`, `.tsx` — was **its own docstring**. It exits with the cut
count, so it was always able to gate. Nothing ran it. In one day the fault it
detects went from one occurrence to four.

The instrument was right, the diagnosis was right, and neither was wired to
anything that would notice. That is the finding worth more than the coordinates.

## What changed today

- `tools/check_walk_severance.py` now prints a last line in the gate runner's
  vocabulary — `WALK SEVERANCE: PASS|FAIL|SKIP — …` — carrying the columns on
  both sides of the first cut, because a coordinate alone is what gate F handed
  over five times running and four of those five were then guessed wrong.
- **SKIP is not PASS.** No built file, or a built file with no cells, used to
  return a quiet zero. A null that reads as green is the instrument lying.
- **A sealed row is now a cut.** `find_cuts` works on adjacent pairs, and a row
  with nothing open in it shares no column with either neighbour — so it was
  skipped as padding, and the most complete severance there is (a row walled end
  to end by bodies, `b`/`p`/`s`) was invisible. Worse, the new SKIP line blamed
  colliders for it. `first_sealed_row` now names it, and only when the flood
  stopped with walkable territory still ahead, which padding never is.
- `severance` is registered in `tools/run_em_gates.py` — the only gate there that
  answers "can a body cross this museum" without booting Godot. It is red now, in
  0.2 s, on a contended tree.
- `tools/test_walk_severance.py` is the negative half: 9 cases over built files
  constructed so the answer is known before the tool runs — whole corridor PASSes,
  one displaced row FAILs, a seam cut says SEAM, a sealed row FAILs, and neither
  a missing file nor an empty one is ever called green.

One thing the test corrected: **a single displaced row is two cuts**, not one —
severed entering it and again leaving it. So "cuts: 4" can mean two faults rather
than four. Today it does mean four, because each of these sits at the end of its
museum's rows and is counted once.

## Why this is a handoff and not a fix

The repair belongs in `_build_courtyard`, and `commons/scenes/endless_museum.gd`
was being actively committed to while this was measured — four commits between
07:21 and 08:31, two Godot processes live, the dirty count climbing 927 → 932
across the session. Both Godot instances hold the `user://` lock, so a builder
change could not have been tested here at all: the only honest verification of a
change to that file is a walk, and the walk needs the headset thread's Godot.

An untested edit to a contended core file, landed by a scheduled agent, is how one
thread's unfinished feature gets swept into another's commit — which has already
happened in both directions in this repo (08-15, 08-16). So the alarm is built and
the mechanism is named; the line is yours.

The shape of the repair, for whoever takes it: the bridge already knows `zcur`, so
it can ask whether `zcur == z0` — whether this court is the one meeting the tile's
back wall — and either align its route to the door columns the tile published
(`gate_layout["door_x0"]/["door_x1"]`, line 3123) or stamp one join row opening
the span between them. The 08-19 measurement says three cells is enough. Whichever
way it goes, `python tools/test_walk_severance.py` and the `severance` gate say
whether it took, in under a second, without the lock.
