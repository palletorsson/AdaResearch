# Point Trace — keep the way through

**Learning elements**

- Ordered position lists
- Sampling conditions
- Indices and neighbour loops
- Pen grip and writing tip

In the Endless Museum's Trace hall, take the red pen from its plinth. Draw a bend, pause, then return towards its beginning. Release the pen. The line remains. Read the retained count and the last ten positions on its plinth.

Lines gave us a segment between two positions. Here we keep positions in order and connect each one to its neighbour. The museum supplies the player, pickup system, pen, renderer and session storage. Work in the existing project; this lesson follows the pen's record.

## Keep accepted positions

Open `commons/primitives/point/draw_dot.gd`. Its list is declared near the top:

**Museum code excerpt**

```gdscript
var _trail_points: Array[Vector3] = []
```

An `Array` is an ordered list. Each entry holds a `Vector3`: three coordinates describing one position. The list has one index, even though each position has three components.

In `_process()`, `_draw_sphere` refers to this pen's `WritingTip`. The recorder reads its world position. While held, recording waits for the grip to arrive; the pickup approach does not become a line. The movement gate then decides whether to consider another reading. The placed pens use a five-millimetre threshold.

**Reduced code excerpt** — the central recording steps in `_process()`, with guards and display work omitted:

```gdscript
var current_global = _draw_sphere.global_position
var dist = current_global.distance_to(_last_global_position)
if dist < min_segment_distance:
    return
_last_global_position = current_global
var rec: Vector3 = _shape_sample(current_global)
_trail_points.append(rec)
```

`append()` adds a value at the end. `_shape_sample()` gives the red pen's positions a ten-millimetre spacing in free space; the green and blue pens use forty and eighty millimetres. The full function also rejects a shaped position equal to the previous retained one. The movement threshold and the shaping grid make different decisions. The comparison position updates when the movement gate passes, even if shaping later rejects that reading.

Keep this experiment away from the whiteboard, where samples can instead be projected onto its face. Pause with a steady hand: time alone adds no entry.

## Follow the order

`_trail_points[0]` reads the first retained position. `_trail_points[1]` reads the second. The plinth numbers these as rows 1 and 2; code indices start at zero.

In `_rebuild_trail()`, the non-fading branch sends the values to a line strip:

**Museum code excerpt**

```gdscript
for point in _trail_points:
    _trail_mesh.surface_add_vertex(point)
```

The renderer connects consecutive vertices. With four entries, it joins 0–1, 1–2 and 2–3. To inspect these pairs explicitly, the existing walking recorder uses this loop in `commons/primitives/point/player_trace.gd`, `get_trail_length()`:

**Museum code excerpt**

```gdscript
for i in range(1, _trail_points.size()):
    length += _trail_points[i].distance_to(_trail_points[i - 1])
```

`range()` stops before the size. Beginning at 1 makes `i - 1` the preceding valid index. This loop visits a retained list; `_process()` revisits the moving pen over time.

Trace your bend in its drawing order. Returning to an earlier place can add another entry there. Release and pick up again: the pen continues its retained list rather than starting a new stroke. Its capacity is 4096 positions; adding beyond that removes the oldest entry.

## Seat the pen in your hand

Open `commons/primitives/point/drawing_pen.gd`, `build_body()`. `WritingGrip` determines the pen's held alignment. `WritingTip` is a separate marker at local Z = −0.155 metres; that is the position we record. Local −Z points towards the nib.

**Student edit** — insert one line after `grip.name = "WritingGrip"`, before `pen.add_child(grip)`:

```gdscript
grip.position.z = -0.03
```

Re-run Trace and pick up the pen with each hand. The grip is now three centimetres towards the nib, shortening the tip's reach from the pickup frame. Turn your wrist and draw another bend. Does the visible nib still meet the start you intended? Compare with the original, then remove the line. This shared helper also builds the board's simple pens.

You have adjusted the held tool while following the same ordered record. Release a drawing with at least two positions before entering Grid. Release copies the whole retained list into `TraceData` for this running session; it does not save a file. Grid will give that record another arrangement without changing its source positions.
