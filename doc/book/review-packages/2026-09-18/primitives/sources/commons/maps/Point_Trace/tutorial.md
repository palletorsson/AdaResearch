# Point Trace

Point_Lines gave us a segment between two positions. Here we keep intermediate positions in order. The lesson is how a reading becomes part of that list, and how the list becomes a drawing.

## Watch a position enter

Draw a short loop with the first dot. Pause, then move again. Compare the point count with two neighbouring rows on the tilted display.

The installed scenes use a 5 mm movement gate. The script can inspect the held point during process callbacks, but a callback need not add a position. This excerpt reduces the recording branch in draw_dot.gd by leaving out display updates, fading and progress bookkeeping:

```gdscript
var current_global = _draw_sphere.global_position
var dist = current_global.distance_to(_last_global_position)

if dist < min_segment_distance:
    return

_last_global_position = current_global
var rec: Vector3 = _shape_sample(current_global)

if not _trail_points.is_empty() and _trail_points[_trail_points.size() - 1].is_equal_approx(rec):
    return

_trail_points.append(rec)
```

The first return declines movement below the threshold. Passing that test updates the comparison position before shaping the sample. The second return declines a shaped position that repeats the preceding saved one. `append()` puts a new accepted position at the end of the list.

The comparison position therefore need not be the last saved position. Movement can pass the first test and still produce a duplicate after shaping. While the tool is released, recording is disabled and the comparison position follows the resting tool.

## Change where a sample can stand

The first dot adds no lattice. The red, green and blue dots use 10, 40 and 80 mm spacing. In free space, the shaping operation rounds each world-coordinate component:

```gdscript
var s: float = resolution_mm / 1000.0
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

These lines show the free-space rounding operation with the position named `rec`. The complete helper also handles nearby whiteboard surfaces. A recording lattice changes spatial grain; it does not set a fixed number of samples per second.

Repeat a small bend, then enlarge it for the coarse recorder. Try deliberately returning to an address. Only consecutive duplicates are rejected: an ordered trace can revisit an earlier position after visiting others.

## Join what was kept

The count is the size of the retained list:

```gdscript
var point_count = _trail_points.size()
```

The mesh uses `Mesh.PRIMITIVE_LINE_STRIP` and supplies the retained positions in order. Each adjacent pair gives a straight segment. The list supplies endpoints for that segment; it does not establish the intervening route of the hand.

The instrument displays the last ten positions while the larger count includes the whole retained list. At most 4096 positions are kept. Beyond that capacity, `pop_front()` removes the oldest position. This is a bounded array maintained by removal, not a circular-buffer implementation. Fading is off in these placements.

## Move the observed point

The stick uses the same recorder and threshold. Its `draw_sphere_path` points to `GrabStick/Blade/Top/TrackBall`. Turning the held rod moves that tip even when the fist changes position very little. The different drawing follows from which point is observed.

At the whiteboard, lift a pen between two marks. The board's separate pen script writes only while held, within the surface bounds and contact allowance. It starts a fresh stroke after the nib leaves. The drawing can omit the journey across the gap.

## Carry the record onward

Releasing a dot or stick calls `TraceData.add_trace(_trail_points)`. The store copies lists containing at least two positions. It survives room changes during the running game; it does not save these traces to disk. Whiteboard pixels follow another storage route.

The copied list contains positions without per-point timestamps. Grid can display and reshape those positions, but cannot recover the timing of a pause from them. That is the record we take into Point_Line_Grid.

See [technical.md](technical.md) for exact source paths, surface rules and the optional timed recorder. Earlier extension sketches are retained in [the previous tutorial](../../../doc/space/point-trace-focus-2026-09-16/previous/tutorial.md).
